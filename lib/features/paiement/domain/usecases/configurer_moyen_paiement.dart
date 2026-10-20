import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class ConfigurerMoyenPaiement {
  final PaiementRepository repository;
  ConfigurerMoyenPaiement(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.configurerMoyen(corps);
}
