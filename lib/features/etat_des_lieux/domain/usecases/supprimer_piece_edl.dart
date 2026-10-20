import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class SupprimerPieceEdl {
  final EtatDesLieuxRepository repository;
  SupprimerPieceEdl(this.repository);

  Future<Either<Failure, void>> call(String id, String pieceId) =>
      repository.supprimerPiece(id, pieceId);
}
