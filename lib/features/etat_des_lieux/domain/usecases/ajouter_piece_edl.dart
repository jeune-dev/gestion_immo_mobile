import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/etat_des_lieux_repository.dart';

class AjouterPieceEdl {
  final EtatDesLieuxRepository repository;
  AjouterPieceEdl(this.repository);

  /// Pièce créée avec les éléments usuels (murs, sols, plafond, portes, fenêtres, électricité).
  Future<Either<Failure, void>> call(String id, String nom) =>
      repository.ajouterPiece(id, {
        'name': nom,
        'items': [
          for (final el in [
            'murs',
            'sols',
            'plafond',
            'portes',
            'fenetres',
            'electricite'
          ])
            {'element': el},
        ],
      });
}
