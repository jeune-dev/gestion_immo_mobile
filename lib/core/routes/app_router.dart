import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/features/abonnement/presentation/pages/abonnement_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/activation_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/changer_mot_de_passe_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/choix_profil_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/connexion_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/espace_pret_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/inscription_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/mot_de_passe_oublie_page.dart';
import 'package:gestion_immo_mobile/core/services/premiere_ouverture.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/locataire/locataire_home_page.dart';
import 'package:gestion_immo_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/proprietaire/proprietaire_home_page.dart';

/// Rafraîchit le routeur à chaque changement de session.
class _Ecoute extends ChangeNotifier {
  late final StreamSubscription<dynamic> _abonnement;

  _Ecoute(Stream<dynamic> flux) {
    _abonnement = flux.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _abonnement.cancel();
    super.dispose();
  }
}

/// Routes de l'application (même rôle que l'`AppRouter` de Sign, sur go_router).
class AppRouter {
  AppRouter._();

  static const demarrage = '/';
  static const onboarding = '/bienvenue';
  static const choixProfil = '/creer-compte';
  static const connexion = '/connexion';
  static const inscription = '/inscription';
  static const motDePasseOublie = '/mot-de-passe-oublie';
  static const activation = '/activation';
  static const motDePasseProvisoire = '/mot-de-passe';
  static const proprietaire = '/p';
  static const abonnement = '/p/abonnement';
  static const espacePret = '/p/espace-pret';
  static const locataire = '/l';

  /// Navigateur racine, pour les ouvertures qui n'ont pas de `BuildContext` :
  /// un appui sur une notification push arrive du système, hors de l'arbre de
  /// widgets, et doit pourtant pousser un écran.
  static final navigateur = GlobalKey<NavigatorState>();

  static const _publiques = [
    onboarding,
    choixProfil,
    connexion,
    inscription,
    motDePasseOublie,
    activation,
  ];

  static GoRouter creer(AuthBloc auth) {
    return GoRouter(
      navigatorKey: navigateur,
      initialLocation: demarrage,
      refreshListenable: _Ecoute(
        auth.stream.map((s) => (s.statut, s.compte)).distinct(),
      ),
      redirect: (context, etat) {
        final s = auth.state;
        final ici = etat.matchedLocation;
        if (s.statut == StatutSession.inconnu) {
          return ici == demarrage ? null : demarrage;
        }
        if (s.statut == StatutSession.deconnecte) {
          // Toute première ouverture : les trois écrans d'accueil, une fois.
          if (!sl<PremiereOuverture>().vu) {
            return ici == onboarding ? null : onboarding;
          }
          return _publiques.contains(ici) ? null : connexion;
        }
        // Connecté : mot de passe provisoire d'abord (403 CHANGEMENT_MOT_DE_PASSE_REQUIS sinon)
        if (s.doitChangerMotDePasse) {
          return ici == motDePasseProvisoire ? null : motDePasseProvisoire;
        }
        final estLocataire = s.compte?.estLocataire ?? false;
        final accueil = estLocataire ? locataire : proprietaire;
        // Compte tout juste créé : un mot d'accueil avant le tableau de bord.
        if (s.nouveauCompte && !estLocataire) {
          return ici == espacePret ? null : espacePret;
        }
        if (ici == demarrage ||
            _publiques.contains(ici) ||
            ici == motDePasseProvisoire) {
          return accueil;
        }
        if (estLocataire && ici.startsWith(proprietaire)) return accueil;
        if (!estLocataire && ici.startsWith(locataire)) return accueil;
        return null;
      },
      routes: [
        GoRoute(path: demarrage, builder: (_, _) => const _Demarrage()),
        GoRoute(path: onboarding, builder: (_, _) => const OnboardingPage()),
        GoRoute(path: choixProfil, builder: (_, _) => const ChoixProfilPage()),
        GoRoute(path: connexion, builder: (_, _) => const ConnexionPage()),
        GoRoute(path: inscription, builder: (_, _) => const InscriptionPage()),
        GoRoute(
          path: motDePasseOublie,
          builder: (_, _) => const MotDePasseOubliePage(),
        ),
        GoRoute(path: activation, builder: (_, _) => const ActivationPage()),
        GoRoute(
          path: motDePasseProvisoire,
          builder: (_, _) => const ChangerMotDePassePage(force: true),
        ),
        GoRoute(
          path: proprietaire,
          builder: (_, _) => const ProprietaireHomePage(),
        ),
        GoRoute(path: abonnement, builder: (_, _) => const AbonnementPage()),
        GoRoute(path: espacePret, builder: (_, _) => const EspacePretPage()),
        GoRoute(path: locataire, builder: (_, _) => const LocataireHomePage()),
      ],
    );
  }
}

class _Demarrage extends StatelessWidget {
  const _Demarrage();

  @override
  Widget build(BuildContext context) {
    final failure = context.select((AuthBloc b) => b.state.failure);
    final enFermeture = context.select((AuthBloc b) => b.state.deconnexion);
    if (failure == null || enFermeture) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final auth = context.read<AuthBloc>();
    // Session gardée : l'utilisateur réessaie, ou repart de la connexion.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(failure.messageComplet, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => auth.add(AuthDemarree()),
                  child: const Text('Réessayer'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => auth.add(DeconnexionDemandee()),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
