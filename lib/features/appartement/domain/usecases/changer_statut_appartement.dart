import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/appartement_repository.dart';

class ChangerStatutAppartement {
  final AppartementRepository repository;
  ChangerStatutAppartement(this.repository);

  Future<Either<Failure, void>> call(String id, String statut) =>
      repository.changerStatutAppartement(id, statut);
}
