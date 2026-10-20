import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/parametres.dart';

abstract class ParametresRepository {
  Future<Either<Failure, ParametresProprietaire>> lire();
  Future<Either<Failure, void>> modifierReglages(Map<String, dynamic> corps);
  Future<Either<Failure, void>> modifierEspace(Map<String, dynamic> corps);
}
