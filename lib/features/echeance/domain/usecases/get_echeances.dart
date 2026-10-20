import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/echeance.dart';
import '../repositories/echeance_repository.dart';

class GetEcheances {
  final EcheanceRepository repository;
  GetEcheances(this.repository);

  Future<Either<Failure, PageResultat<Echeance>>> call({
    required int page,
    String? bailId,
    String? locataireId,
    bool impayes = false,
    String? statut,
  }) =>
      repository.getEcheances(
          page: page,
          bailId: bailId,
          locataireId: locataireId,
          impayes: impayes,
          statut: statut);
}
