import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:flutter/foundation.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';
import '../../domain/entities/compte.dart';
import '../../domain/entities/resultat_connexion.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ApiClient api;
  final TokenService jetons;
  final FileAttenteService fileAttente;

  AuthRepositoryImpl(
      {required this.remoteDataSource,
      required this.api,
      required this.jetons,
      required this.fileAttente});

  static const _appareil = 'Application mobile';
  String get _plateforme =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> _ouvrir(Map<String, dynamic> data) => jetons.enregistrer(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String?);

  @override
  Future<bool> sessionEnregistree() async => await jetons.lireRefresh() != null;

  @override
  Future<bool> restaurerSession() => api.renouveler();

  @override
  Future<Either<Failure, ResultatConnexion>> connecter(
      {required String identifiant, required String motDePasse}) async {
    try {
      final r = await remoteDataSource.connecter({
        'identifiant': identifiant.trim(),
        'password': motDePasse,
        'device_name': _appareil,
        'platform': _plateforme
      });
      if (r['mfa_requis'] == true) {
        return Right(DoubleAuthentificationRequise(r['mfa_token'] as String));
      }
      await _ouvrir(r);
      return Right(const SessionOuverte());
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> verifierMfa(
      {required String jeton, String? code, String? codeSecours}) async {
    try {
      await _ouvrir(
        await remoteDataSource.verifierMfa({
          'mfa_token': jeton,
          if (code != null) 'code': code,
          if (codeSecours != null) 'code_secours': codeSecours,
          'device_name': _appareil,
          'platform': _plateforme
        }),
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> inscrireProprietaire(
      Map<String, dynamic> corps) async {
    try {
      await _ouvrir(await remoteDataSource.inscrire(corps));
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> activerLocataire(
      Map<String, dynamic> corps) async {
    try {
      await _ouvrir(await remoteDataSource.activerLocataire(
          {...corps, 'device_name': _appareil, 'platform': _plateforme}));
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  /// Le serveur renvoie une nouvelle session (les autres appareils sont déconnectés).
  @override
  Future<Either<Failure, void>> changerMotDePasse(
      {required String actuel, required String nouveau}) async {
    try {
      final r = await remoteDataSource.changerMotDePasse({
        'current_password': actuel,
        'password': nouveau,
        'password_confirmation': nouveau,
        'refresh_token': await jetons.lireRefresh(),
      });
      await _ouvrir(r);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, Compte>> lireCompte() async {
    try {
      final resultat = await remoteDataSource.lireCompte();
      return Right(resultat);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<void> deconnecter() async {
    try {
      await remoteDataSource.deconnecter(await jetons.lireRefresh());
    } catch (_) {
      // La session locale est fermée même sans réseau
    }
    await jetons.effacer();
    await ApiClient.viderCache();
    await fileAttente.vider();
  }

  @override
  Future<Either<Failure, void>> demanderReinitialisation(
      String identifiant) async {
    try {
      await remoteDataSource.demanderReinitialisation(identifiant.trim());
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }

  @override
  Future<Either<Failure, void>> reinitialiserMotDePasse(
      Map<String, dynamic> corps) async {
    try {
      await remoteDataSource.reinitialiserMotDePasse(corps);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(
          ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'));
    }
  }
}
