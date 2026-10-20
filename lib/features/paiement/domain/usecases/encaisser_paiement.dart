import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class EncaisserPaiement {
  final PaiementRepository repository;
  EncaisserPaiement(this.repository);

  Future<Either<Failure, int>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.encaisser(corps, cle: cle);
}
