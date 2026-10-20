import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class ModifierProfil {
  final AccountRepository repository;
  ModifierProfil(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.modifierProfil(corps);
}
