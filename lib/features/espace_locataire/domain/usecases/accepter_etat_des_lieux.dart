import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class AccepterEtatDesLieux {
  final EspaceLocataireRepository repository;
  AccepterEtatDesLieux(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.accepterEtatDesLieux(id);
}
