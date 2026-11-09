import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';

import '../../domain/entities/session_appareil.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final TokenService jetons;
  AccountRepositoryImpl({required this.remoteDataSource, required this.jetons});

  @override
  Future<Either<Failure, void>> modifierProfil(Map<String, dynamic> corps) =>
      appelApi(() => remoteDataSource.modifierProfil(corps));

  @override
  Future<Either<Failure, Uint8List>> lirePhoto() =>
      appelApi(() => remoteDataSource.lirePhoto());

  @override
  Future<Either<Failure, void>> envoyerPhoto(String chemin) =>
      appelApi(() => remoteDataSource.envoyerPhoto(chemin));

  @override
  Future<Either<Failure, void>> supprimerPhoto() =>
      appelApi(() => remoteDataSource.supprimerPhoto());

  @override
  Future<Either<Failure, List<SessionAppareil>>> sessions() =>
      appelApi(() => remoteDataSource.sessions());

  @override
  Future<Either<Failure, void>> revoquerSession(String id) =>
      appelApi(() => remoteDataSource.revoquerSession(id));

  @override
  Future<Either<Failure, void>> revoquerAutres() =>
      appelApi(() => remoteDataSource.revoquerAutres());

  @override
  Future<Either<Failure, SecretMfa>> initialiserMfa(String motDePasse) =>
      appelApi(() => remoteDataSource.initialiserMfa(motDePasse));

  /// L'activation ouvre une nouvelle session : les jetons sont remplacés.
  @override
  Future<Either<Failure, List<String>>> activerMfa(String code) =>
      appelApi(() async {
        final r = await remoteDataSource.activerMfa(code);
        await jetons.enregistrer(
          access: r['access_token'] as String,
          refresh: r['refresh_token'] as String?,
        );
        return ((r['codes_secours'] as List?) ?? const []).cast<String>();
      });

  @override
  Future<Either<Failure, void>> desactiverMfa({
    required String motDePasse,
    required String code,
  }) => appelApi(
    () => remoteDataSource.desactiverMfa(motDePasse: motDePasse, code: code),
  );

  @override
  Future<Either<Failure, List<String>>> regenererCodesSecours({
    required String motDePasse,
    required String code,
  }) => appelApi(
    () => remoteDataSource.regenererCodesSecours(
      motDePasse: motDePasse,
      code: code,
    ),
  );
}
