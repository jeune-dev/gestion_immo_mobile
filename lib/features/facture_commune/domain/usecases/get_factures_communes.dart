import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/facture_commune.dart';
import '../repositories/facture_commune_repository.dart';

class GetFacturesCommunes {
  final FactureCommuneRepository repository;
  GetFacturesCommunes(this.repository);

  Future<Either<Failure, PageResultat<FactureCommune>>> call(
          {required int page, String? statut}) =>
      repository.getFacturesCommunes(page: page, statut: statut);
}
