import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class PreciserElementEdl {
  final EtatDesLieuxRepository repository;
  PreciserElementEdl(this.repository);

  /// Précision (libellé) de l'élément ; `null` l'efface.
  Future<Either<Failure, void>> call(
          String id, String elementId, String? precision) =>
      repository.modifierElement(id, elementId, {'label': precision});
}
