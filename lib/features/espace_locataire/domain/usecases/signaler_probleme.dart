import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import '../repositories/espace_locataire_repository.dart';

class SignalerProbleme {
  final EspaceLocataireRepository repository;
  SignalerProbleme(this.repository);

  /// `Right(null)` : enregistré hors ligne, envoyé au retour du réseau (§ 34).
  Future<Either<Failure, Incident?>> call(Map<String, dynamic> corps) =>
      repository.signalerOuDifferer(corps);
}
