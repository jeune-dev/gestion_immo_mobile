import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

import '../repositories/bail_repository.dart';

/// Étapes d'accord d'un bail : proposition au locataire, bail ou avenant signé
/// sur papier, retrait d'un avenant, congé.
class ActionBail {
  final BailRepository repository;
  ActionBail(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    String id,
    String chemin, {
    Map<String, dynamic> corps = const {},
    String? fichier,
  }) => repository.action(id, chemin, corps: corps, fichier: fichier);
}
