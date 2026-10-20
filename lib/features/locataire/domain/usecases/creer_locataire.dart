import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/locataire.dart';
import '../repositories/locataire_repository.dart';

class CreerLocataire {
  final LocataireRepository repository;
  CreerLocataire(this.repository);

  Future<Either<Failure, LocataireCree>> call(
    Map<String, dynamic> data, {
    required String cle,
  }) =>
      repository.creerLocataire(data, cle: cle);
}
