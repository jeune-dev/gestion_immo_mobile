import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/features/abonnement/presentation/pages/abonnement_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/activation_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/changer_mot_de_passe_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/connexion_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/inscription_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/pages/mot_de_passe_oublie_page.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/locataire/locataire_home_page.dart';
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
  static const connexion = '/connexion';
  static const inscription = '/inscription';
  static const motDePasseOublie = '/mot-de-passe-oublie';
  static const activation = '/activation';
  static const motDePasseProvisoire = '/mot-de-passe';
  static const proprietaire = '/p';
  static const abonnement = '/p/abonnement';
  static const locataire = '/l';

  static const _publiques = [
    connexion,
    inscription,
    motDePasseOublie,
    activation
  ];

  static GoRouter creer(AuthBloc auth) {
    return GoRouter(
      initialLocation: demarrage,
      refreshListenable:
          _Ecoute(auth.stream.map((s) => (s.statut, s.compte)).distinct()),
      redirect: (context, etat) {
        final s = auth.state;
        final ici = etat.matchedLocation;
        if (s.statut == StatutSession.inconnu) {
          return ici == demarrage ? null : demarrage;
        }
        if (s.statut == StatutSession.deconnecte) {
          return _publiques.contains(ici) ? null : connexion;
        }
        // Connecté : mot de passe provisoire d'abord (403 CHANGEMENT_MOT_DE_PASSE_REQUIS sinon)
        if (s.doitChangerMotDePasse) {
          return ici == motDePasseProvisoire ? null : motDePasseProvisoire;
        }
        final estLocataire = s.compte?.estLocataire ?? false;
        final accueil = estLocataire ? locataire : proprietaire;
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
        GoRoute(path: connexion, builder: (_, _) => const ConnexionPage()),
        GoRoute(path: inscription, builder: (_, _) => const InscriptionPage()),
        GoRoute(
            path: motDePasseOublie,
            builder: (_, _) => const MotDePasseOubliePage()),
        GoRoute(path: activation, builder: (_, _) => const ActivationPage()),
        GoRoute(
            path: motDePasseProvisoire,
            builder: (_, _) => const ChangerMotDePassePage(force: true)),
        GoRoute(
            path: proprietaire,
            builder: (_, _) => const ProprietaireHomePage()),
        GoRoute(path: abonnement, builder: (_, _) => const AbonnementPage()),
        GoRoute(path: locataire, builder: (_, _) => const LocataireHomePage()),
      ],
    );
  }
}

class _Demarrage extends StatelessWidget {
  const _Demarrage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
