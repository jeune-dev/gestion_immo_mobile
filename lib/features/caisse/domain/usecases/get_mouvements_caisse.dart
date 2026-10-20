import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/caisse.dart';
import '../repositories/caisse_repository.dart';

class GetMouvementsCaisse {
  final CaisseRepository repository;
  GetMouvementsCaisse(this.repository);

  Future<Either<Failure, PageResultat<MouvementCaisse>>> call(
          {required int page, required String du, required String au}) =>
      repository.mouvements(page: page, du: du, au: au);
}
