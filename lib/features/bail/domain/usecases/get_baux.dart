import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/bail.dart';
import '../repositories/bail_repository.dart';

class GetBaux {
  final BailRepository repository;
  GetBaux(this.repository);

  Future<Either<Failure, PageResultat<Bail>>> call(
          {required int page, String? statut, String? recherche}) =>
      repository.getBaux(page: page, statut: statut, recherche: recherche);
}
