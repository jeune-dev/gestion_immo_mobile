import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class AjouterElementEdl {
  final EtatDesLieuxRepository repository;
  AjouterElementEdl(this.repository);

  Future<Either<Failure, void>> call(
          String id, String pieceId, Map<String, dynamic> corps) =>
      repository.ajouterElement(id, pieceId, corps);
}
