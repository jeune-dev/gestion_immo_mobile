import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/travaux_repository.dart';

class ChangerStatutTravaux {
  final TravauxRepository repository;
  ChangerStatutTravaux(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.changerStatutTravaux(id, corps);
}
