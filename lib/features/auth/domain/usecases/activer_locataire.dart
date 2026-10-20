import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ActiverLocataire {
  final AuthRepository repository;
  ActiverLocataire(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps) =>
      repository.activerLocataire(corps);
}
