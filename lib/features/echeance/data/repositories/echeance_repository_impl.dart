import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/echeance.dart';
import '../../domain/entities/echeance_detail.dart';
import '../../domain/repositories/echeance_repository.dart';
import '../datasources/echeance_remote_datasource.dart';

class EcheanceRepositoryImpl implements EcheanceRepository {
  final EcheanceRemoteDataSource remoteDataSource;
  EcheanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Echeance>>> getEcheances({
    required int page,
    String? bailId,
    String? locataireId,
    bool impayes = false,
    String? statut,
  }) => appelApi(
    () => remoteDataSource.getEcheances(
      page: page,
      bailId: bailId,
      locataireId: locataireId,
      impayes: impayes,
      statut: statut,
    ),
  );

  @override
  Future<Either<Failure, EcheanceDetail>> getEcheance(
    String id, {
    bool espaceLocataire = false,
  }) => appelApi(
    () => remoteDataSource.getEcheance(id, espaceLocataire: espaceLocataire),
  );

  @override
  Future<Either<Failure, void>> annulerEcheance(String id, String motif) =>
      appelApi(() => remoteDataSource.annulerEcheance(id, motif));
}
