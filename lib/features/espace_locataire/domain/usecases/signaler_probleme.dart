import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';

import '../repositories/espace_locataire_repository.dart';

class SignalerProbleme {
  final EspaceLocataireRepository repository;
  SignalerProbleme(this.repository);

  /// [cle] : la même pour un même formulaire, un nouvel essai ne crée pas de doublon.
  Future<Either<Failure, Incident>> call(
    Map<String, dynamic> corps, {
    required String cle,
  }) => repository.signaler(corps, cle: cle);
}
