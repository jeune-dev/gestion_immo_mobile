import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/caution_repository.dart';

class RetenirCaution {
  final CautionRepository repository;
  RetenirCaution(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      repository.retenir(id, corps, cle: cle);
}
