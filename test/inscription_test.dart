import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/activer_locataire.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/changer_mot_de_passe.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/connecter.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/deconnecter.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/demander_code_inscription.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/get_compte.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/inscrire_proprietaire.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/restaurer_session.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/verifier_code_inscription.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/verifier_mfa.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/inscription_page.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

/// Dépôt simulé : retient ce qui part au serveur pour les deux appels de la
/// vérification d'adresse, et refuse le code quand [codeRefuse] est vrai.
class _Depot implements AuthRepository {
  final adressesVerifiees = <String>[];
  final codesSoumis = <String>[];
  bool codeRefuse = false;

  @override
  Future<Either<Failure, void>> demanderCodeInscription(
    String email, {
    String? prenom,
  }) async {
    adressesVerifiees.add(email);
    return const Right(null);
  }

  @override
  Future<Either<Failure, String>> verifierCodeInscription(
    String email,
    String code,
  ) async {
    codesSoumis.add(code);
    return codeRefuse
        ? const Left(ServerFailure(errorMessage: 'Code incorrect ou expiré.'))
        : const Right('jeton-de-verification');
  }

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
  late _Depot depot;
  late _Bloc bloc;

  setUp(() {
    depot = _Depot();
    bloc = _Bloc(depot);
    sl
      ..registerSingleton(DemanderCodeInscription(depot))
      ..registerSingleton(VerifierCodeInscription(depot));
  });
  tearDown(() async {
    await bloc.close();
    await sl.reset();
  });

  Future<void> ouvrir(
    WidgetTester t, {
    Size taille = const Size(402, 900),
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

  Future<void> saisir(WidgetTester t, String exemple, String valeur) =>
      t.enterText(find.widgetWithText(TextFormField, exemple), valeur);

  Future<void> continuer(WidgetTester t, String libelle) async {
    await t.tap(find.widgetWithText(FilledButton, libelle));
    await t.pumpAndSettle();
  }

  /// Remplit les trois premières étapes et demande le code.
  Future<void> jusquAuCode(WidgetTester t) async {
    await saisir(t, 'Awa', ' Awa ');
    await saisir(t, 'Diop', 'Diop');
    await continuer(t, 'Continuer');
    await saisir(t, 'exemple@email.com', 'Awa@Demo.SN');
    await saisir(t, '77 123 45 67', '77 123 45 67');
    await continuer(t, 'Continuer');
    await saisir(t, 'Choisissez un mot de passe', 'Secret123');
    await continuer(t, 'Recevoir mon code');
  }

  /// Saisit les six chiffres ; la vérification part toute seule à la fin.
  Future<void> saisirCode(WidgetTester t, String code) async {
    for (var i = 0; i < code.length; i++) {
      await t.enterText(find.byType(TextField).at(i), code[i]);
    }
    await t.pumpAndSettle();
  }

  testWidgets('la première étape se présente seule, avec sa progression', (
    t,
  ) async {
    await ouvrir(t);
    expect(find.text('Votre nom'), findsOneWidget);
    expect(find.textContaining('ÉTAPE 1 SUR 5'), findsOneWidget);
    expect(find.text('Awa'), findsOneWidget);
    // Les champs des étapes suivantes ne sont pas encore là.
    expect(find.text('exemple@email.com'), findsNothing);
    expect(find.text('Déjà un compte ?'), findsNothing);
    expect(find.textContaining('Déjà un compte'), findsOneWidget);
  });

  testWidgets('une étape incomplète ne laisse pas passer', (t) async {
    await ouvrir(t);
    await continuer(t, 'Continuer');
    expect(find.text('Obligatoire'), findsNWidgets(2));
    expect(find.text('Votre nom'), findsOneWidget);
  });

  testWidgets('le code part à l’adresse saisie, normalisée', (t) async {
    await ouvrir(t);
    await jusquAuCode(t);
    expect(depot.adressesVerifiees, ['awa@demo.sn']);
    expect(find.text('Vérifiez votre e-mail'), findsOneWidget);
    expect(find.textContaining('ÉTAPE 4 SUR 5'), findsOneWidget);
    // Une case par chiffre.
    expect(find.byType(TextField), findsNWidgets(6));
    // Le compte n'existe pas encore : l'adresse est vérifiée d'abord.
    expect(bloc.demandes, isEmpty);
  });

  testWidgets('le code complet est vérifié sans toucher au bouton', (t) async {
    await ouvrir(t);
    await jusquAuCode(t);
    await saisirCode(t, '048213');
    expect(depot.codesSoumis, ['048213']);
    expect(find.text('Votre activité'), findsOneWidget);
  });

  testWidgets('un code refusé garde sur l’étape, avec son message', (t) async {
    depot.codeRefuse = true;
    await ouvrir(t);
    await jusquAuCode(t);
    await saisirCode(t, '000000');
    expect(find.text('Vérifiez votre e-mail'), findsOneWidget);
    expect(find.textContaining('Code incorrect'), findsOneWidget);
    expect(bloc.demandes, isEmpty);
  });

  testWidgets('le compte part avec le jeton de vérification', (t) async {
    await ouvrir(t);
    await jusquAuCode(t);
    await saisirCode(t, '048213');
    await saisir(t, 'Diop Immobilier', 'Diop Immobilier');
    await saisir(t, 'Dakar', 'Dakar');
    await continuer(t, 'Terminer');
    expect(bloc.demandes.single, {
      'first_name': 'Awa',
      'last_name': 'Diop',
      'phone': '+221771234567',
      'email': 'awa@demo.sn',
      'password': 'Secret123',
      'password_confirmation': 'Secret123',
      'company_name': 'Diop Immobilier',
      'city': 'Dakar',
      'email_token': 'jeton-de-verification',
    });
  });

  testWidgets('société et ville restent facultatives', (t) async {
    await ouvrir(t);
    await jusquAuCode(t);
    await saisirCode(t, '048213');
    await continuer(t, 'Terminer');
    expect(bloc.demandes.single.containsKey('company_name'), isFalse);
    expect(bloc.demandes.single.containsKey('city'), isFalse);
  });

  testWidgets('les règles du mot de passe se cochent au fil de la saisie', (
    t,
  ) async {
    await ouvrir(t);
    await saisir(t, 'Awa', 'Awa');
    await saisir(t, 'Diop', 'Diop');
    await continuer(t, 'Continuer');
    await saisir(t, 'exemple@email.com', 'awa@demo.sn');
    await saisir(t, '77 123 45 67', '771234567');
    await continuer(t, 'Continuer');
    expect(find.byIcon(Icons.check), findsNothing);
    await saisir(t, 'Choisissez un mot de passe', 'Secret12');
    await t.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(4));
  });

  testWidgets('revenir en arrière rend la main sur l’étape précédente', (
    t,
  ) async {
    await ouvrir(t);
    await saisir(t, 'Awa', 'Awa');
    await saisir(t, 'Diop', 'Diop');
    await continuer(t, 'Continuer');
    expect(find.text('Vos coordonnées'), findsOneWidget);
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.text('Votre nom'), findsOneWidget);
    // La saisie n'est pas perdue.
    expect(find.text('Awa'), findsWidgets);
  });

  for (final (l, h) in [(320.0, 568.0), (390.0, 844.0)]) {
    testWidgets('écran ${l.toInt()}×${h.toInt()} : aucune étape ne déborde', (
      t,
    ) async {
      await ouvrir(t, taille: Size(l, h));
      await jusquAuCode(t);
      await saisirCode(t, '048213');
      await continuer(t, 'Terminer');
      expect(t.takeException(), isNull);
    });
  }
}
