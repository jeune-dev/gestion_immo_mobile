import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/activer_locataire.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/changer_mot_de_passe.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/connecter.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/deconnecter.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/get_compte.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/inscrire_proprietaire.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/restaurer_session.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/verifier_mfa.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/inscription_page.dart';

class _Depot implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation appel) => super.noSuchMethod(appel);
}

/// Retient la demande d'inscription sans appeler de dépôt.
class _Bloc extends AuthBloc {
  final demandes = <Map<String, dynamic>>[];
  _Bloc(_Depot d)
    : super(
        restaurerSession: RestaurerSession(d),
        connecter: Connecter(d),
        verifierMfa: VerifierMfa(d),
        inscrireProprietaire: InscrireProprietaire(d),
        activerLocataire: ActiverLocataire(d),
        changerMotDePasse: ChangerMotDePasse(d),
        getCompte: GetCompte(d),
        deconnecter: Deconnecter(d),
      );

  @override
  void add(AuthEvent event) {
    if (event is InscriptionDemandee) {
      demandes.add(event.corps);
    } else {
      super.add(event);
    }
  }
}

void main() {
  late _Bloc bloc;
  setUp(() => bloc = _Bloc(_Depot()));
  tearDown(() => bloc.close());

  Future<void> ouvrir(
    WidgetTester t, {
    Size taille = const Size(402, 1600),
  }) async {
    t.view.physicalSize = taille * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.clair,
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const InscriptionPage(),
        ),
      ),
    );
    await t.pump();
  }

  Future<void> saisir(WidgetTester t, String exemple, String valeur) async {
    await t.enterText(find.widgetWithText(TextFormField, exemple), valeur);
  }

  Future<void> envoyer(WidgetTester t) async {
    await t.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await t.pump();
  }

  testWidgets('parties, libellés et exemples visibles avant la saisie', (
    t,
  ) async {
    await ouvrir(t);
    for (final texte in [
      'Votre identité',
      'Vos coordonnées',
      'Votre activité',
      'Votre mot de passe',
      'exemple@email.com',
      '77 123 45 67',
      'Déjà un compte ?',
    ]) {
      expect(find.text(texte), findsOneWidget, reason: texte);
    }
  });

  testWidgets('formulaire vide : erreurs affichées, rien n’est envoyé', (
    t,
  ) async {
    await ouvrir(t);
    await envoyer(t);
    expect(find.text('Obligatoire'), findsNWidgets(5));
    expect(find.text('8 caractères minimum'), findsOneWidget);
    expect(bloc.demandes, isEmpty);
  });

  testWidgets('saisie conforme : envoyée au format de l’API', (t) async {
    await ouvrir(t);
    await saisir(t, 'Awa', ' Awa ');
    await saisir(t, 'Diop', 'Diop');
    await saisir(t, '77 123 45 67', '77 123 45 67');
    await saisir(t, 'exemple@email.com', 'Awa@Demo.SN');
    await saisir(t, 'Choisissez un mot de passe', 'Secret123');
    await saisir(t, 'Saisissez-le à nouveau', 'Secret123');
    await envoyer(t);
    expect(bloc.demandes.single, {
      'first_name': 'Awa',
      'last_name': 'Diop',
      'phone': '+221771234567',
      'email': 'awa@demo.sn',
      'password': 'Secret123',
      'password_confirmation': 'Secret123',
    });
  });

  testWidgets('confirmation différente : refusée', (t) async {
    await ouvrir(t);
    await saisir(t, 'Choisissez un mot de passe', 'Secret123');
    await saisir(t, 'Saisissez-le à nouveau', 'Autre1234');
    await envoyer(t);
    expect(find.text('Les mots de passe diffèrent'), findsOneWidget);
  });

  testWidgets('règles du mot de passe cochées au fil de la saisie', (t) async {
    await ouvrir(t);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await saisir(t, 'Choisissez un mot de passe', 'Secret12');
    await t.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
  });

  for (final (l, h) in [(320.0, 568.0), (390.0, 844.0)]) {
    testWidgets('écran ${l.toInt()}×${h.toInt()} : aucun débordement', (
      t,
    ) async {
      await ouvrir(t, taille: Size(l, h));
      await t.ensureVisible(
        find.widgetWithText(FilledButton, 'Créer mon compte'),
      );
      await t.pumpAndSettle();
      await envoyer(t);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
