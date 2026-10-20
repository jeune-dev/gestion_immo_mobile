import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/immeuble.dart';
import '../repositories/immeuble_repository.dart';

class GetImmeubles {
  final ImmeubleRepository repository;
  GetImmeubles(this.repository);

  Future<Either<Failure, PageResultat<Immeuble>>> call(
          {required int page, String? recherche}) =>
      repository.getImmeubles(page: page, recherche: recherche);
}
