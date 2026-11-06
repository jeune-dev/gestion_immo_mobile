import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../entities/depense.dart';
import '../repositories/depense_repository.dart';

class CreerDepense {
  final DepenseRepository repository;
  CreerDepense(this.repository);

  /// [cle] : la même pour un même formulaire, un nouvel essai ne crée pas de doublon.
  Future<Either<Failure, Depense>> call(
    Map<String, dynamic> corps, {
    required String cle,
  }) => repository.creerDepense(corps, cle: cle);
}
