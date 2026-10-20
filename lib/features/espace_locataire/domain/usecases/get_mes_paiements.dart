import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesPaiements {
  final EspaceLocataireRepository repository;
  GetMesPaiements(this.repository);

  Future<Either<Failure, PageResultat<Paiement>>> call({required int page}) =>
      repository.paiements(page: page);
}
