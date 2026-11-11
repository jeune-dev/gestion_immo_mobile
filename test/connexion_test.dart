import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/features/auth/domain/entities/resultat_connexion.dart';
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
import 'package:gestion_immo_mobile/features/auth/presentation/pages/connexion_page.dart';

/// Dépôt simulé : retient l'identifiant envoyé et refuse la connexion.
class _Depot implements AuthRepository {
  final envois = <String>[];

  @override
  dynamic noSuchMethod(Invocation appel) {
    if (appel.memberName == #connecter) {
      envois.add(appel.namedArguments[#identifiant] as String);
      return Future.value(
        const Left<Failure, ResultatConnexion>(
          ServerFailure(errorMessage: 'Refusé'),
        ),
      );
    }
    return super.noSuchMethod(appel);
  }
}

void main() {
  group('téléphone', () {
    test('toutes les écritures donnent le format de l’API', () {
      for (final saisie in [
        '77 123 45 67',
        '771234567',
        '77-123-45-67',
        '0771234567',
        '+221 77 123 45 67',
        '00221771234567',
        '221771234567',
      ]) {
        expect(
          IdentifiantValidator.telephone(saisie).valeur,
          '+221771234567',
          reason: saisie,
        );
      }
      expect(
        IdentifiantValidator.telephone('+33 6 12 34 56 78').valeur,
        '+33612345678',
      );
    });

    test('refus : vide, trop court, trop long, lettres', () {
      String? erreur(String s) =>
          IdentifiantValidator.telephone(s, obligatoire: true).erreurFormulaire;
      expect(erreur(''), 'Obligatoire');
      expect(erreur('77 123'), isNotNull);
      expect(erreur('7712345678'), isNotNull);
      expect(erreur('77abc4567'), isNotNull);
      expect(erreur('+2217'), isNotNull);
    });
  });

  group('autres règles', () {
    test('identifiant : e-mail ou téléphone', () {
      expect(
        IdentifiantValidator.identifiant(' Awa@Demo.sn ').valeur,
        'awa@demo.sn',
      );
      expect(
        IdentifiantValidator.identifiant('77 123 45 67').valeur,
        '+221771234567',
      );
      expect(
        IdentifiantValidator.identifiant('').erreurFormulaire,
        'Obligatoire',
      );
      expect(
        IdentifiantValidator.identifiant('awa@').erreurFormulaire,
        isNotNull,
      );
      expect(
        IdentifiantValidator.identifiant('abc').erreurFormulaire,
        isNotNull,
      );
    });

    test('mot de passe : trop long refusé', () {
      expect(
        IdentifiantValidator.motDePasse('Aa1${'x' * 130}').erreurFormulaire,
        '128 caractères maximum',
      );
    });
  });

  group('page de connexion', () {
    late _Depot depot;
    late AuthBloc bloc;

    setUp(() {
      depot = _Depot();
      bloc = AuthBloc(
        restaurerSession: RestaurerSession(depot),
        connecter: Connecter(depot),
        verifierMfa: VerifierMfa(depot),
        inscrireProprietaire: InscrireProprietaire(depot),
        activerLocataire: ActiverLocataire(depot),
        changerMotDePasse: ChangerMotDePasse(depot),
        getCompte: GetCompte(depot),
        deconnecter: Deconnecter(depot),
      );
    });
    tearDown(() => bloc.close());

    Future<void> ouvrir(WidgetTester t) async {
      t.view.physicalSize = const Size(1170, 3000);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.clair,
          home: BlocProvider.value(value: bloc, child: const ConnexionPage()),
        ),
      );
      await t.pump();
    }

    Finder champ(String cle) => find.byKey(ValueKey(cle));
    final motDePasse = find.byType(TextFormField).at(1);
    final bouton = find.text('Se connecter');

    testWidgets('e-mail par défaut : format contrôlé, puis envoi normalisé', (
      t,
    ) async {
      await ouvrir(t);
      expect(champ('connexion-email'), findsOneWidget);
      expect(champ('connexion-telephone'), findsNothing);

      // Exemples visibles avant toute saisie.
      expect(find.text('exemple@email.com'), findsOneWidget);
      expect(find.text('Votre mot de passe'), findsOneWidget);
      expect(find.text('Je suis propriétaire'), findsOneWidget);
      expect(find.text('Je suis locataire'), findsOneWidget);

      await t.tap(bouton);
      await t.pump();
      expect(find.text('Obligatoire'), findsWidgets);
      expect(depot.envois, isEmpty);

      await t.enterText(champ('connexion-email'), 'awa@demo');
      await t.enterText(motDePasse, 'secret');
      await t.tap(bouton);
      await t.pump();
      expect(find.text('E-mail invalide'), findsOneWidget);
      expect(depot.envois, isEmpty);

      await t.enterText(champ('connexion-email'), ' Awa@Demo.sn ');
      await t.tap(bouton);
      await t.pump();
      expect(depot.envois, ['awa@demo.sn']);
    });

    testWidgets(
      'téléphone : autre champ, contrôlé et envoyé au format de l’API',
      (t) async {
        await ouvrir(t);
        await t.tap(find.text('Téléphone'));
        await t.pumpAndSettle();
        expect(champ('connexion-email'), findsNothing);
        expect(champ('connexion-telephone'), findsOneWidget);
        expect(find.text('77 123 45 67'), findsOneWidget);

        await t.enterText(champ('connexion-telephone'), '77 12');
        await t.enterText(motDePasse, 'secret');
        await t.tap(bouton);
        await t.pump();
        expect(find.text('Le numéro doit contenir 9 chiffres'), findsOneWidget);
        expect(depot.envois, isEmpty);

        await t.enterText(champ('connexion-telephone'), '77 123 45 67');
        await t.tap(bouton);
        await t.pump();
        expect(depot.envois, ['+221771234567']);
      },
    );

    for (final (largeur, hauteur) in [
      (320.0, 568.0),
      (375.0, 667.0),
      (390.0, 844.0),
    ]) {
      testWidgets(
        'écran ${largeur.toInt()}×${hauteur.toInt()} : aucun débordement, tout reste accessible',
        (t) async {
          t.view.physicalSize = Size(largeur * 3, hauteur * 3);
          t.view.devicePixelRatio = 3;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme.clair,
              home: BlocProvider.value(
                value: bloc,
                child: const ConnexionPage(),
              ),
            ),
          );
          await t.pump();
          await t.tap(bouton);
          await t.pump();
          await t.ensureVisible(find.text('Je suis locataire'));
          await t.pumpAndSettle();
          expect(
            t.getBottomLeft(find.text('Je suis locataire')).dy,
            lessThanOrEqualTo(hauteur),
          );
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets('changer d’onglet garde chaque saisie', (t) async {
      await ouvrir(t);
      await t.enterText(champ('connexion-email'), 'awa@demo.sn');
      await t.tap(find.text('Téléphone'));
      await t.pumpAndSettle();
      await t.enterText(champ('connexion-telephone'), '771234567');
      await t.tap(find.text('E-mail'));
      await t.pumpAndSettle();
      expect(find.text('awa@demo.sn'), findsOneWidget);
      await t.tap(find.text('Téléphone'));
      await t.pumpAndSettle();
      expect(find.text('771234567'), findsOneWidget);
    });
  });
}
