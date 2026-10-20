import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import '../repositories/espace_locataire_repository.dart';

class GetMesCharges {
  final EspaceLocataireRepository repository;
  GetMesCharges(this.repository);

  Future<Either<Failure, PageResultat<ChargeRefacturee>>> call(
          {required int page}) =>
      repository.charges(page: page);
}
