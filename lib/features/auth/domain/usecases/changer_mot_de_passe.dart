import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ChangerMotDePasse {
  final AuthRepository repository;
  ChangerMotDePasse(this.repository);

  Future<Either<Failure, void>> call(
          {required String actuel, required String nouveau}) =>
      repository.changerMotDePasse(actuel: actuel, nouveau: nouveau);
}
