import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class RenommerPieceEdl {
  final EtatDesLieuxRepository repository;
  RenommerPieceEdl(this.repository);

  Future<Either<Failure, void>> call(String id, String pieceId, String nom) =>
      repository.modifierPiece(id, pieceId, {'name': nom});
}
