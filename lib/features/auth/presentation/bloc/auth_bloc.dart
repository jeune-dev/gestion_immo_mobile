import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/auth_event_bus.dart';

import '../../domain/entities/resultat_connexion.dart';
import '../../domain/usecases/activer_locataire.dart';
import '../../domain/usecases/changer_mot_de_passe.dart';
import '../../domain/usecases/connecter.dart';
import '../../domain/usecases/deconnecter.dart';
import '../../domain/usecases/get_compte.dart';
import '../../domain/usecases/inscrire_proprietaire.dart';
import '../../domain/usecases/restaurer_session.dart';
import '../../domain/usecases/verifier_mfa.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Session globale de l'application (rôle de l'`AuthBloc` de Sign).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RestaurerSession restaurerSession;
  final Connecter connecter;
  final VerifierMfa verifierMfa;
  final InscrireProprietaire inscrireProprietaire;
  final ActiverLocataire activerLocataire;
  final ChangerMotDePasse changerMotDePasse;
  final GetCompte getCompte;
  final Deconnecter deconnecter;
  late final StreamSubscription<String?> _expiration;

  /// Une fermeture à la fois : une expiration peut survenir pendant la déconnexion.
  bool _fermetureEnCours = false;

  static const _sessionExpiree =
      'Votre session a expiré. Reconnectez-vous pour continuer.';

  AuthBloc({
    required this.restaurerSession,
    required this.connecter,
    required this.verifierMfa,
    required this.inscrireProprietaire,
    required this.activerLocataire,
    required this.changerMotDePasse,
    required this.getCompte,
    required this.deconnecter,
  }) : super(const AuthState()) {
    on<AuthDemarree>(_onDemarree);
    on<ConnexionDemandee>(_onConnexion);
    on<MfaSoumise>(_onMfa);
    on<MfaAbandonnee>(
      (_, emit) => emit(state.copyWith(effacerMfa: true, effacerFailure: true)),
    );
    on<InscriptionDemandee>(
      (e, emit) => _ouvrir(emit, () => inscrireProprietaire(e.corps)),
    );
    on<ActivationDemandee>(
      (e, emit) => _ouvrir(emit, () => activerLocataire(e.corps)),
    );
    on<MotDePasseChangeDemande>(_onMotDePasse);
    on<CompteRechargeDemande>(_onRecharge);
    on<DeconnexionDemandee>(_onDeconnexion);
    on<SessionExpiree>(_onSessionExpiree);
    on<AuthErreurEffacee>(
      (_, emit) =>
          emit(state.copyWith(effacerFailure: true, effacerSucces: true)),
    );
    _expiration = AuthEventBus.instance.onLogout.listen((motif) {
      if (state.connecte) add(SessionExpiree(motif));
    });
  }

  Future<void> _onDemarree(AuthDemarree e, Emitter<AuthState> emit) async {
    // Nouvel essai depuis l'écran d'erreur : retour à l'attente.
    if (state.failure != null) emit(const AuthState());
    try {
      final r = await restaurerSession();
      if (r == SessionRestauree.aucune) {
        return emit(const AuthState(statut: StatutSession.deconnecte));
      }
      if (r == SessionRestauree.refusee) return await _fermerExpiree(emit);
      final compte = await getCompte();
      await compte.fold(
        (f) async {
          // Jeton encore là : le serveur est en cause, pas la session. L'écran
          // de démarrage propose de réessayer au lieu de la perdre.
          if (await restaurerSession.sessionPresente()) {
            emit(AuthState(failure: f));
          } else {
            await _fermerExpiree(emit);
          }
        },
        (c) async => emit(AuthState(statut: StatutSession.connecte, compte: c)),
      );
    } catch (e) {
      debugPrint('Restauration de session impossible : $e');
      emit(
        const AuthState(
          failure: CacheFailure(
            errorMessage:
                'Impossible de lire la session enregistrée sur ce téléphone.',
          ),
        ),
      );
    }
  }

  /// Ferme la session sur l'appareil sans laisser une erreur bloquer l'écran.
  Future<void> _fermer({required bool sessionExpiree}) async {
    try {
      await deconnecter(sessionExpiree: sessionExpiree);
    } catch (e) {
      debugPrint('Fermeture de session en échec : $e');
    }
  }

  Future<void> _fermerExpiree(Emitter<AuthState> emit, [String? motif]) async {
    await _fermer(sessionExpiree: true);
    emit(
      AuthState(
        statut: StatutSession.deconnecte,
        information: motif ?? _sessionExpiree,
      ),
    );
  }

  Future<void> _onConnexion(
    ConnexionDemandee e,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        enCours: true,
        effacerFailure: true,
        effacerInformation: true,
      ),
    );
    final r = await connecter(
      identifiant: e.identifiant,
      motDePasse: e.motDePasse,
    );
    await r.fold(
      (f) async => emit(state.copyWith(enCours: false, failure: f)),
      (resultat) async => switch (resultat) {
        DoubleAuthentificationRequise(:final jeton) => emit(
          state.copyWith(enCours: false, mfaJeton: jeton),
        ),
        SessionOuverte() => _chargerCompte(emit, nouvelleSession: true),
      },
    );
  }

  Future<void> _onMfa(MfaSoumise e, Emitter<AuthState> emit) async {
    final jeton = state.mfaJeton;
    if (jeton == null) return;
    emit(state.copyWith(enCours: true, effacerFailure: true));
    final r = await verifierMfa(
      jeton: jeton,
      code: e.code,
      codeSecours: e.codeSecours,
    );
    await r.fold(
      // Jeton expiré : retour à l'identifiant et au mot de passe
      (f) async => emit(
        state.copyWith(
          enCours: false,
          failure: f,
          effacerMfa: f.code == 'JETON_MFA_INVALIDE',
        ),
      ),
      (_) => _chargerCompte(emit, nouvelleSession: true),
    );
  }

  Future<void> _ouvrir(
    Emitter<AuthState> emit,
    Future<Either<Failure, void>> Function() action,
  ) async {
    emit(state.copyWith(enCours: true, effacerFailure: true));
    final r = await action();
    await r.fold(
      (f) async => emit(state.copyWith(enCours: false, failure: f)),
      (_) => _chargerCompte(emit, nouvelleSession: true),
    );
  }

  Future<void> _onMotDePasse(
    MotDePasseChangeDemande e,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(enCours: true, effacerFailure: true, effacerSucces: true),
    );
    final r = await changerMotDePasse(actuel: e.actuel, nouveau: e.nouveau);
    await r.fold(
      (f) async => emit(state.copyWith(enCours: false, failure: f)),
      (_) => _chargerCompte(
        emit,
        succes:
            'Mot de passe modifié. Les autres appareils ont été déconnectés.',
      ),
    );
  }

  Future<void> _onRecharge(
    CompteRechargeDemande e,
    Emitter<AuthState> emit,
  ) async {
    final r = await getCompte();
    r.fold((_) {}, (c) => emit(state.copyWith(compte: c)));
  }

  /// [nouvelleSession] : sans le compte, la session à peine ouverte est refermée,
  /// pour qu'un nouvel essai n'en laisse pas une seconde sur le serveur.
  Future<void> _chargerCompte(
    Emitter<AuthState> emit, {
    String? succes,
    bool nouvelleSession = false,
  }) async {
    final r = await getCompte();
    await r.fold(
      (f) async {
        if (nouvelleSession) await _fermer(sessionExpiree: true);
        emit(
          state.copyWith(
            enCours: false,
            failure: f,
            effacerMfa: nouvelleSession,
          ),
        );
      },
      (c) async => emit(
        AuthState(
          statut: StatutSession.connecte,
          compte: c,
          succes: succes,
          version: state.version + (succes == null ? 0 : 1),
        ),
      ),
    );
  }

  Future<void> _onDeconnexion(AuthEvent e, Emitter<AuthState> emit) async {
    if (_fermetureEnCours) return;
    _fermetureEnCours = true;
    emit(state.copyWith(deconnexion: true));
    await _fermer(sessionExpiree: false);
    _fermetureEnCours = false;
    emit(const AuthState(statut: StatutSession.deconnecte));
  }

  Future<void> _onSessionExpiree(
    SessionExpiree e,
    Emitter<AuthState> emit,
  ) async {
    if (_fermetureEnCours || state.statut == StatutSession.deconnecte) return;
    _fermetureEnCours = true;
    await _fermerExpiree(emit, e.motif);
    _fermetureEnCours = false;
  }

  @override
  Future<void> close() {
    _expiration.cancel();
    return super.close();
  }
}
