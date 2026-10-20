import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/messagerie_repository.dart';

class MarquerFilLu {
  final MessagerieRepository repository;
  MarquerFilLu(this.repository);

  Future<Either<Failure, void>> call(String filId,
          {bool espaceLocataire = false}) =>
      repository.marquerLu(filId, espaceLocataire: espaceLocataire);
}
