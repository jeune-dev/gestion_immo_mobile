import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/facture_commune_repository.dart';

class JoindreDocumentFacture {
  final FactureCommuneRepository repository;
  JoindreDocumentFacture(this.repository);

  Future<Either<Failure, void>> call(String id, String chemin) =>
      repository.joindreDocument(id, chemin);
}
