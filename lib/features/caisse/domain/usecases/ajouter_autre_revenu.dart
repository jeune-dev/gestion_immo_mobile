import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/caisse_repository.dart';

class AjouterAutreRevenu {
  final CaisseRepository repository;
  AjouterAutreRevenu(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> corps,
          {required String cle}) =>
      repository.ajouterAutreRevenu(corps, cle: cle);
}
