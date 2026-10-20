import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class RembourserPaiement {
  final PaiementRepository repository;
  RembourserPaiement(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      repository.rembourser(id, corps, cle: cle);
}
