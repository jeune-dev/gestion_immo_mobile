import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/caution_repository.dart';

class VerserCaution {
  final CautionRepository repository;
  VerserCaution(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      repository.verser(id, corps, cle: cle);
}
