import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/bail.dart';
import '../repositories/bail_repository.dart';

class CreerBail {
  final BailRepository repository;
  CreerBail(this.repository);

  Future<Either<Failure, Bail>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.creerBail(corps, cle: cle);
}
