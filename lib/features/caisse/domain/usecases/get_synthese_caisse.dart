import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/caisse.dart';
import '../repositories/caisse_repository.dart';

class GetSyntheseCaisse {
  final CaisseRepository repository;
  GetSyntheseCaisse(this.repository);

  Future<Either<Failure, SyntheseCaisse>> call(
          {required String du, required String au}) =>
      repository.synthese(du: du, au: au);
}
