import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../api/api_client.dart';
import '../services.dart';

enum EtatSession { inconnu, deconnecte, connecte }

/// Session de l'utilisateur et espace à afficher (propriétaire ou locataire).
@immutable
class Session {
  const Session({this.etat = EtatSession.inconnu, this.user, this.owner, this.abonnement});

  final EtatSession etat;

  /// `GET /compte` → `user` (role_code, must_change_password…).
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? owner;

  /// `{ abonnement, plan, actif }` pour un propriétaire.
  final Map<String, dynamic>? abonnement;

  String? get role => user?['role_code'] as String? ?? user?['role'] as String?;
  bool get estProprietaire => role == 'proprietaire';
  bool get estLocataire => role == 'locataire';
  bool get doitChangerMotDePasse => user?['must_change_password'] == true;

  /// Abonnement échu ou suspendu : l'espace propriétaire est en lecture seule (402).
  bool get lectureSeule => estProprietaire && abonnement != null && abonnement!['actif'] != true;
}

/// Résultat de la 1re étape de connexion quand la double authentification est active.
class MfaRequise {
  const MfaRequise(this.jeton);
  final String jeton;
}

class SessionCubit extends Cubit<Session> {
  SessionCubit() : super(const Session()) {
    api.onSessionExpiree = () {
      if (state.etat == EtatSession.connecte) _fermer();
    };
  }

  static const _appareil = {'device_name': 'Application mobile'};

  String get _plateforme => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Au lancement : session restaurée depuis le refresh token du coffre.
  Future<void> demarrer() async {
    final refresh = await Services.session.lireRefresh();
    if (refresh == null) return emit(const Session(etat: EtatSession.deconnecte));
    if (await api.renouveler()) {
      try {
        return await chargerCompte();
      } catch (_) {
        // Compte illisible : retour à la connexion
      }
    } else if (await Services.session.lireRefresh() != null) {
      // Pas de réseau : la session reste valable, on attend une reconnexion
      try {
        return await chargerCompte();
      } catch (_) {}
    }
    emit(const Session(etat: EtatSession.deconnecte));
  }

  Future<void> chargerCompte() async {
    final c = await api.get<Map<String, dynamic>>('/compte');
    emit(Session(
      etat: EtatSession.connecte,
      user: Map<String, dynamic>.from(c['user'] as Map),
      owner: c['owner'] == null ? null : Map<String, dynamic>.from(c['owner'] as Map),
      abonnement: c['abonnement'] == null ? null : Map<String, dynamic>.from(c['abonnement'] as Map),
    ));
  }

  Future<void> _ouvrir(Map<String, dynamic> data) async {
    await Services.session.enregistrer(access: data['access_token'] as String, refresh: data['refresh_token'] as String?);
    await chargerCompte();
  }

  /// Renvoie [MfaRequise] si un code de double authentification est attendu.
  Future<MfaRequise?> connecter(String identifiant, String motDePasse) async {
    final r = await api.post<Map<String, dynamic>>('/auth/connexion',
        body: {'identifiant': identifiant.trim(), 'password': motDePasse, ..._appareil, 'platform': _plateforme},
        sansJeton: true);
    if (r['mfa_requis'] == true) return MfaRequise(r['mfa_token'] as String);
    await _ouvrir(r);
    return null;
  }

  Future<void> verifierMfa(String jeton, {String? code, String? codeSecours}) async {
    final r = await api.post<Map<String, dynamic>>('/auth/mfa',
        body: {
          'mfa_token': jeton,
          'code': ?code,
          'code_secours': ?codeSecours,
          ..._appareil,
          'platform': _plateforme,
        },
        sansJeton: true);
    await _ouvrir(r);
  }

  Future<void> inscrire(Map<String, dynamic> corps) async {
    final r = await api.post<Map<String, dynamic>>('/auth/inscription', body: corps, sansJeton: true);
    await _ouvrir(r);
  }

  /// Activation du compte locataire avec le code d'invitation (§ 5 option B).
  Future<void> activerLocataire(Map<String, dynamic> corps) async {
    final r = await api.post<Map<String, dynamic>>('/auth/locataire/activation',
        body: {...corps, ..._appareil, 'platform': _plateforme}, sansJeton: true);
    await _ouvrir(r);
  }

  /// Le serveur renvoie une nouvelle session (les autres appareils sont déconnectés).
  Future<void> changerMotDePasse(String actuel, String nouveau) async {
    final r = await api.post<Map<String, dynamic>>('/compte/mot-de-passe', body: {
      'current_password': actuel,
      'password': nouveau,
      'password_confirmation': nouveau,
      'refresh_token': await Services.session.lireRefresh(),
    });
    await Services.session.enregistrer(access: r['access_token'] as String, refresh: r['refresh_token'] as String?);
    await chargerCompte();
  }

  Future<void> deconnecter() async {
    try {
      final refresh = await Services.session.lireRefresh();
      await api.post<dynamic>('/auth/deconnexion', body: {'refresh_token': refresh}, sansJeton: true);
    } catch (_) {
      // La session locale est fermée même sans réseau
    }
    await _fermer();
  }

  Future<void> _fermer() async {
    await Services.session.effacer();
    await ApiClient.viderCache();
    await Services.fileAttente.vider();
    emit(const Session(etat: EtatSession.deconnecte));
  }
}
