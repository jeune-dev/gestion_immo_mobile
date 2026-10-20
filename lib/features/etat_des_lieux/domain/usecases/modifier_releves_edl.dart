import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class ModifierRelevesEdl {
  final EtatDesLieuxRepository repository;
  ModifierRelevesEdl(this.repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> corps) =>
      repository.modifierEtatDesLieux(id, corps);
}
