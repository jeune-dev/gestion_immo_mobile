import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/locataire.dart';
import '../repositories/locataire_repository.dart';

class ModifierLocataire {
  final LocataireRepository repository;
  ModifierLocataire(this.repository);

  Future<Either<Failure, Locataire>> call(
    String id,
    Map<String, dynamic> data,
  ) =>
      repository.modifierLocataire(id, data);
}
