import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../entities/echeance.dart';
import '../entities/echeance_detail.dart';

abstract class EcheanceRepository {
  Future<Either<Failure, PageResultat<Echeance>>> getEcheances({
    required int page,
    String? bailId,
    String? locataireId,
    bool impayes = false,
    String? statut,
  });
  Future<Either<Failure, EcheanceDetail>> getEcheance(
    String id, {
    bool espaceLocataire = false,
  });
  Future<Either<Failure, void>> annulerEcheance(String id, String motif);
}
