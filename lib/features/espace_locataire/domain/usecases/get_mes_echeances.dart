import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesEcheances {
  final EspaceLocataireRepository repository;
  GetMesEcheances(this.repository);

  Future<Either<Failure, PageResultat<Echeance>>> call(
          {required int page, bool aPayer = false}) =>
      repository.echeances(page: page, aPayer: aPayer);
}
