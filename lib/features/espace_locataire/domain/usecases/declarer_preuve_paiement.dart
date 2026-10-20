import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class DeclarerPreuvePaiement {
  final EspaceLocataireRepository repository;
  DeclarerPreuvePaiement(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> champs,
          {String? capture}) =>
      repository.declarerPreuve(champs, capture: capture);
}
