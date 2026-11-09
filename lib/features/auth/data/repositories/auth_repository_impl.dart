import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/utils/journal.dart';
import 'package:gestion_immo_mobile/core/services/push_service.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:flutter/foundation.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';

import '../../domain/entities/compte.dart';
import '../../domain/entities/resultat_connexion.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ApiClient api;
  final TokenService jetons;
  final PushService? push;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.api,
    required this.jetons,
    this.push,
  });

  static const _appareil = 'Application mobile';

  /// Temps accordé aux derniers envois avant de fermer la session sur l'appareil.
  static const _delaiDerniersEnvois = Duration(seconds: 8);
  static const _delaiRevocation = Duration(seconds: 5);

  String get _plateforme =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> _ouvrir(Map<String, dynamic> data) => jetons.enregistrer(
    access: data['access_token'] as String,
    refresh: data['refresh_token'] as String?,
  );

  /// Nouvelle session : envoie aussi la révocation restée en attente.
  Future<void> _ouvrirNouvelleSession(Map<String, dynamic> data) async {
    await _ouvrir(data);
    unawaited(_envoyerRevocationReportee());
  }

  /// Révocation d'une session fermée sans réseau ; gardée tant que le réseau manque.
  Future<void> _envoyerRevocationReportee() async {
    try {
      final jeton = await jetons.lireRevocation();
      if (jeton == null) return;
      await remoteDataSource.deconnecter(jeton);
      await jetons.oublierRevocation();
    } on ApiException catch (e) {
      if (!_aRetenter(e)) await jetons.oublierRevocation();
    } catch (e) {
      journalDebug('Révocation différée impossible : $e');
    }
  }

  bool _aRetenter(ApiException e) =>
      e.estReseau || e.status == 429 || (e.status ?? 500) >= 500;

  @override
  Future<bool> sessionEnregistree() async => await jetons.lireRefresh() != null;

  @override
  Future<bool> restaurerSession() {
    unawaited(_envoyerRevocationReportee());
    return api.renouveler();
  }

  @override
  Future<Either<Failure, ResultatConnexion>> connecter({
    required String identifiant,
    required String motDePasse,
  }) => appelApi(() async {
    final r = await remoteDataSource.connecter({
      'identifiant': identifiant.trim(),
      'password': motDePasse,
      'device_name': _appareil,
      'platform': _plateforme,
    });
    if (r['mfa_requis'] == true) {
      return DoubleAuthentificationRequise(r['mfa_token'] as String);
    }
    await _ouvrirNouvelleSession(r);
    return const SessionOuverte();
  });

  @override
  Future<Either<Failure, void>> verifierMfa({
    required String jeton,
    String? code,
    String? codeSecours,
  }) => appelApi(
    () async => _ouvrirNouvelleSession(
      await remoteDataSource.verifierMfa({
        'mfa_token': jeton,
        if (code != null) 'code': code,
        if (codeSecours != null) 'code_secours': codeSecours,
        'device_name': _appareil,
        'platform': _plateforme,
      }),
    ),
  );

  @override
  Future<Either<Failure, void>> inscrireProprietaire(
    Map<String, dynamic> corps,
  ) => appelApi(
    () async => _ouvrirNouvelleSession(await remoteDataSource.inscrire(corps)),
  );

  @override
  Future<Either<Failure, void>> activerLocataire(Map<String, dynamic> corps) =>
      appelApi(
        () async => _ouvrirNouvelleSession(
          await remoteDataSource.activerLocataire({
            ...corps,
            'device_name': _appareil,
            'platform': _plateforme,
          }),
        ),
      );

  /// Le serveur renvoie une nouvelle session (les autres appareils sont déconnectés).
  @override
  Future<Either<Failure, void>> changerMotDePasse({
    required String actuel,
    required String nouveau,
  }) => appelApi(() async {
    final r = await remoteDataSource.changerMotDePasse({
      'current_password': actuel,
      'password': nouveau,
      'password_confirmation': nouveau,
      'refresh_token': await jetons.lireRefresh(),
    });
    await _ouvrir(r);
  });

  @override
  Future<Either<Failure, Compte>> lireCompte() =>
      appelApi(() => remoteDataSource.lireCompte());

  @override
  Future<void> deconnecter({bool sessionExpiree = false}) async {
    // Chaque étape peut échouer : la session se ferme quand même sur l'appareil.
    await _sansErreur(() => _derniersEnvois().timeout(_delaiDerniersEnvois));
    await _sansErreur(_revoquerSession);
    await _sansErreur(jetons.effacer);
  }

  Future<void> _derniersEnvois() async {
    await push?.arreter();
    await api.attendreRenouvellement();
  }

  Future<void> _revoquerSession() async {
    final refresh = await jetons.lireRefresh();
    if (refresh == null) return;
    try {
      await remoteDataSource.deconnecter(refresh).timeout(_delaiRevocation);
    } on ApiException catch (e) {
      if (_aRetenter(e)) await jetons.reporterRevocation(refresh);
    } on TimeoutException {
      await jetons.reporterRevocation(refresh);
    }
  }

  Future<void> _sansErreur(Future<void> Function() etape) async {
    try {
      await etape();
    } catch (e) {
      journalDebug('Déconnexion : étape en échec ($e)');
    }
  }

  @override
  Future<Either<Failure, void>> demanderReinitialisation(String identifiant) =>
      appelApi(
        () => remoteDataSource.demanderReinitialisation(identifiant.trim()),
      );

  @override
  Future<Either<Failure, void>> verifierCodeReinitialisation(
    String identifiant,
    String code,
  ) => appelApi(
    () =>
        remoteDataSource.verifierCodeReinitialisation(identifiant.trim(), code),
  );

  @override
  Future<Either<Failure, void>> reinitialiserMotDePasse(
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.reinitialiserMotDePasse(corps));
}
