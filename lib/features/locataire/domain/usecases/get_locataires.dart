import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/locataire.dart';
import '../repositories/locataire_repository.dart';

class GetLocataires {
  final LocataireRepository repository;
  GetLocataires(this.repository);

  Future<Either<Failure, PageResultat<Locataire>>> call({
    required int page,
    String? recherche,
  }) =>
      repository.getLocataires(page: page, recherche: recherche);
}
