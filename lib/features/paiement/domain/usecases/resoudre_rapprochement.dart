import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class ResoudreRapprochement {
  final PaiementRepository repository;
  ResoudreRapprochement(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      repository.resoudreRapprochement(id, corps, cle: cle);
}
