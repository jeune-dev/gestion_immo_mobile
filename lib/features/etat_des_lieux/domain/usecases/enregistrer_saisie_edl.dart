import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class EnregistrerSaisieEdl {
  final EtatDesLieuxRepository repository;
  EnregistrerSaisieEdl(this.repository);

  /// Saisie synchronisée d'un bloc (§ 52.4) : `{ item_id, condition, comment }` par élément.
  Future<Either<Failure, void>> call(
          String id, List<Map<String, dynamic>> elements) =>
      repository.enregistrerSaisie(id, elements);
}
