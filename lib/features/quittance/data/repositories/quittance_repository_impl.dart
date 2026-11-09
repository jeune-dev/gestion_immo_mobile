import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/quittance.dart';
import '../../domain/repositories/quittance_repository.dart';
import '../datasources/quittance_remote_datasource.dart';

class QuittanceRepositoryImpl implements QuittanceRepository {
  final QuittanceRemoteDataSource remoteDataSource;
  QuittanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Quittance>>> getQuittances({
    required int page,
    required bool espaceLocataire,
  }) => appelApi(
    () => remoteDataSource.getQuittances(
      page: page,
      espaceLocataire: espaceLocataire,
    ),
  );

  @override
  Future<Either<Failure, Quittance>> getQuittance(
    String id, {
    required bool espaceLocataire,
  }) => appelApi(
    () => remoteDataSource.getQuittance(id, espaceLocataire: espaceLocataire),
  );

  @override
  Future<Either<Failure, Uint8List>> pdf(
    String id, {
    required bool espaceLocataire,
  }) => appelApi(
    () => remoteDataSource.pdf(id, espaceLocataire: espaceLocataire),
  );
}
