import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/services/premiere_ouverture.dart';
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
import 'package:gestion_immo_mobile/features/auth/presentation/pages/activation_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/choix_profil_page.dart';
import 'package:gestion_immo_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

class _Depot implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation appel) => super.noSuchMethod(appel);
}

/// Retient l'activation sans appeler de dépôt.
class _Bloc extends AuthBloc {
  final activations = <Map<String, dynamic>>[];
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
    if (event is ActivationDemandee) {
      activations.add(event.corps);
    } else {
      super.add(event);
    }
  }
}

/// Coffre simulé : garde ce qu'on y écrit, le temps du test.
class _Coffre extends FlutterSecureStorage {
  final Map<String, String> contenu;
  const _Coffre(this.contenu);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => contenu[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      contenu.remove(key);
    } else {
      contenu[key] = value;
    }
  }
}

/// Un écran d'arrivée, pour vérifier où mène un bouton.
Widget _arrivee(String nom) => Scaffold(body: Center(child: Text(nom)));

void main() {
  group('première ouverture', () {
    test('la marque est posée dans le coffre, et relue ensuite', () async {
      final contenu = <String, String>{};
      final premiere = PremiereOuverture(_Coffre(contenu));
      expect(await premiere.charger(), isFalse);
      expect(premiere.vu, isFalse);

      await premiere.marquerVu();
      expect(premiere.vu, isTrue);
      // Une nouvelle ouverture de l'application relit la même marque.
      expect(await PremiereOuverture(_Coffre(contenu)).charger(), isTrue);
    });

    test('un coffre en panne ne fait pas revenir l’onboarding', () async {
      final premiere = PremiereOuverture(const _CoffreEnPanne());
      expect(await premiere.charger(), isTrue);
    });
  });

  group('onboarding', () {
    late Map<String, String> contenu;

    setUp(() {
      contenu = <String, String>{};
      sl.registerSingleton(PremiereOuverture(_Coffre(contenu)));
    });
    tearDown(() => sl.reset());

    Future<void> ouvrir(WidgetTester t) async {
      t.view.physicalSize = const Size(402 * 3, 900 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.clair,
          routerConfig: GoRouter(
            initialLocation: AppRouter.onboarding,
            routes: [
              GoRoute(
                path: AppRouter.onboarding,
                builder: (_, _) => const OnboardingPage(),
              ),
              GoRoute(
                path: AppRouter.choixProfil,
                builder: (_, _) => _arrivee('choix du profil'),
              ),
              GoRoute(
                path: AppRouter.connexion,
                builder: (_, _) => _arrivee('connexion'),
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('le premier écran marque l’onboarding comme vu', (t) async {
      await ouvrir(t);
      expect(find.textContaining('Tous vos biens'), findsOneWidget);
      // Posée à l'affichage : fermer l'application ici ne le fait pas revenir.
      expect(contenu['gi.onboarding_vu'], 'oui');
    });

    testWidgets('« Passer » mène droit au choix du profil', (t) async {
      await ouvrir(t);
      await t.tap(find.text('Passer'));
      await t.pumpAndSettle();
      expect(find.text('choix du profil'), findsOneWidget);
    });

    testWidgets('le dernier écran propose « Commencer », sans « Passer »', (
      t,
    ) async {
      await ouvrir(t);
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text('Suivant'));
        await t.pumpAndSettle();
      }
      expect(find.textContaining('Vos locataires'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);
      await t.tap(find.text('Commencer'));
      await t.pumpAndSettle();
      expect(find.text('choix du profil'), findsOneWidget);
    });
  });

  group('choix du profil', () {
    Future<void> ouvrir(WidgetTester t) async {
      // Surface d'un téléphone : la surface par défaut des tests (800×600)
      // laisserait le bouton hors de l'écran.
      t.view.physicalSize = const Size(402 * 3, 900 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.clair,
          routerConfig: GoRouter(
            initialLocation: AppRouter.choixProfil,
            routes: [
              GoRoute(
                path: AppRouter.choixProfil,
                builder: (_, _) => const ChoixProfilPage(),
              ),
              GoRoute(
                path: AppRouter.inscription,
                builder: (_, _) => _arrivee('inscription'),
              ),
              GoRoute(
                path: AppRouter.activation,
                builder: (_, _) => _arrivee('activation'),
              ),
              GoRoute(
                path: AppRouter.connexion,
                builder: (_, _) => _arrivee('connexion'),
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('les deux profils sont posés côte à côte', (t) async {
      await ouvrir(t);
      expect(find.text('Je suis propriétaire'), findsOneWidget);
      expect(find.text('Je suis locataire'), findsOneWidget);
      expect(find.textContaining('Déjà un compte'), findsOneWidget);
    });

    testWidgets('propriétaire est proposé par défaut', (t) async {
      await ouvrir(t);
      await t.tap(find.text('Continuer'));
      await t.pumpAndSettle();
      expect(find.text('inscription'), findsOneWidget);
    });

    testWidgets('choisir locataire mène à l’activation', (t) async {
      await ouvrir(t);
      await t.tap(find.text('Je suis locataire'));
      await t.pumpAndSettle();
      await t.tap(find.text('Continuer'));
      await t.pumpAndSettle();
      expect(find.text('activation'), findsOneWidget);
    });
  });

  group('activation du locataire', () {
    late _Bloc bloc;
    setUp(() => bloc = _Bloc(_Depot()));
    tearDown(() => bloc.close());

    Future<void> ouvrir(
      WidgetTester t, {
      Size taille = const Size(402, 900),
    }) async {
      t.view.physicalSize = taille * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.clair,
          routerConfig: GoRouter(
            initialLocation: AppRouter.activation,
            routes: [
              GoRoute(
                path: AppRouter.activation,
                builder: (_, _) => BlocProvider<AuthBloc>.value(
                  value: bloc,
                  child: const ActivationPage(),
                ),
              ),
              GoRoute(
                path: AppRouter.connexion,
                builder: (_, _) => _arrivee('connexion'),
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> saisirCode(WidgetTester t, String code) async {
      for (var i = 0; i < code.length; i++) {
        await t.enterText(find.byType(TextField).at(i), code[i]);
      }
      await t.pump();
    }

    Future<void> continuer(WidgetTester t, String libelle) async {
      await t.tap(find.widgetWithText(FilledButton, libelle));
      await t.pumpAndSettle();
    }

    testWidgets('le code d’invitation a ses huit cases', (t) async {
      await ouvrir(t);
      expect(find.text('Activer mon espace'), findsOneWidget);
      expect(find.textContaining('ÉTAPE 1 SUR 2'), findsOneWidget);
      // Huit cases de code, plus le champ du téléphone.
      expect(find.byType(TextField), findsNWidgets(9));
      // Le mot de passe ne se demande qu'ensuite.
      expect(find.text('Choisissez un mot de passe'), findsNothing);
    });

    testWidgets('un code incomplet ne laisse pas passer', (t) async {
      await ouvrir(t);
      await saisirCode(t, '7304');
      await continuer(t, 'Continuer');
      expect(find.textContaining('les 8 chiffres'), findsOneWidget);
      expect(find.text('Activer mon espace'), findsOneWidget);
    });

    testWidgets('code, téléphone et mot de passe partent ensemble', (t) async {
      await ouvrir(t);
      await saisirCode(t, '73041596');
      await t.enterText(
        find.widgetWithText(TextFormField, "Celui qu'il a enregistré"),
        '77 123 45 67',
      );
      await continuer(t, 'Continuer');
      expect(find.text('Votre mot de passe'), findsOneWidget);

      await t.enterText(
        find.widgetWithText(TextFormField, 'Choisissez un mot de passe'),
        'Secret123',
      );
      await continuer(t, 'Entrer dans mon espace');
      expect(bloc.activations.single, {
        'code': '73041596',
        'phone': '+221771234567',
        'password': 'Secret123',
        'password_confirmation': 'Secret123',
      });
    });

    testWidgets('écran 320×568 : aucune étape ne déborde', (t) async {
      await ouvrir(t, taille: const Size(320, 568));
      await saisirCode(t, '73041596');
      await t.enterText(
        find.widgetWithText(TextFormField, "Celui qu'il a enregistré"),
        '771234567',
      );
      await continuer(t, 'Continuer');
      await t.enterText(
        find.widgetWithText(TextFormField, 'Choisissez un mot de passe'),
        'Secret123',
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });
}

/// Coffre qui refuse de répondre (appareil sans Keychain accessible).
class _CoffreEnPanne extends FlutterSecureStorage {
  const _CoffreEnPanne();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw Exception('coffre indisponible');
}
