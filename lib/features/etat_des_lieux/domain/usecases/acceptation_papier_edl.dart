import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/etat_des_lieux_repository.dart';

/// État des lieux signé sur papier par un locataire sans application.
class AcceptationPapierEdl {
  final EtatDesLieuxRepository repository;
  AcceptationPapierEdl(this.repository);

  Future<Either<Failure, void>> call(String id, String photo) =>
      repository.acceptationPapier(id, photo);
}
