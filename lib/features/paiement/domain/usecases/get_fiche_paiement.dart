import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetFichePaiement {
  final PaiementRepository repository;
  GetFichePaiement(this.repository);

  Future<Either<Failure, FichePaiement>> call(String id) =>
      repository.getFichePaiement(id);
}
