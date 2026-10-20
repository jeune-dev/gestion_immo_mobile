import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/caution_repository.dart';

class AjouterJustificatifCaution {
  final CautionRepository repository;
  AjouterJustificatifCaution(this.repository);

  /// Renvoie l'identifiant du document, à citer dans la retenue (§ 55.4).
  Future<Either<Failure, String>> call(String id, String chemin) =>
      repository.ajouterJustificatif(id, chemin);
}
