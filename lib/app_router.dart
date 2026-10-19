import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/session_cubit.dart';
import 'features/auth/activation_screen.dart';
import 'features/auth/changer_mot_de_passe_screen.dart';
import 'features/auth/connexion_screen.dart';
import 'features/auth/inscription_screen.dart';
import 'features/auth/mot_de_passe_oublie_screen.dart';
import 'features/locataire/locataire_shell.dart';
import 'features/proprietaire/abonnement_screen.dart';
import 'features/proprietaire/proprietaire_shell.dart';

/// Rafraîchit le routeur à chaque changement de session.
class _Ecoute extends ChangeNotifier {
  _Ecoute(Stream<dynamic> flux) {
    _abonnement = flux.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _abonnement;

  @override
  void dispose() {
    _abonnement.cancel();
    super.dispose();
  }
}

const _publiques = ['/connexion', '/inscription', '/mot-de-passe-oublie', '/activation'];

GoRouter creerRouteur(SessionCubit session) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _Ecoute(session.stream),
    redirect: (context, etat) {
      final s = session.state;
      final ici = etat.matchedLocation;
      if (s.etat == EtatSession.inconnu) return ici == '/' ? null : '/';
      if (s.etat == EtatSession.deconnecte) return _publiques.contains(ici) ? null : '/connexion';
      // Connecté : mot de passe provisoire d'abord (403 CHANGEMENT_MOT_DE_PASSE_REQUIS sinon)
      if (s.doitChangerMotDePasse) return ici == '/mot-de-passe' ? null : '/mot-de-passe';
      final accueil = s.estLocataire ? '/l' : '/p';
      if (ici == '/' || _publiques.contains(ici) || ici == '/mot-de-passe') return accueil;
      if (s.estLocataire && ici.startsWith('/p')) return accueil;
      if (s.estProprietaire && ici.startsWith('/l')) return accueil;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _Demarrage()),
      GoRoute(path: '/connexion', builder: (_, _) => const ConnexionScreen()),
      GoRoute(path: '/inscription', builder: (_, _) => const InscriptionScreen()),
      GoRoute(path: '/mot-de-passe-oublie', builder: (_, _) => const MotDePasseOublieScreen()),
      GoRoute(path: '/activation', builder: (_, _) => const ActivationScreen()),
      GoRoute(path: '/mot-de-passe', builder: (_, _) => const ChangerMotDePasseScreen(force: true)),
      GoRoute(path: '/p', builder: (_, _) => const ProprietaireShell()),
      GoRoute(path: '/p/abonnement', builder: (_, _) => const AbonnementScreen()),
      GoRoute(path: '/l', builder: (_, _) => const LocataireShell()),
    ],
  );
}

class _Demarrage extends StatelessWidget {
  const _Demarrage();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
