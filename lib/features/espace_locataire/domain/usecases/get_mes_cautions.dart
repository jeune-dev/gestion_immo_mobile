import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesCautions {
  final EspaceLocataireRepository repository;
  GetMesCautions(this.repository);

  Future<Either<Failure, List<Caution>>> call() => repository.cautions();
}
