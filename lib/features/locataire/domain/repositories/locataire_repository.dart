import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/locataire.dart';

abstract class LocataireRepository {
  Future<Either<Failure, PageResultat<Locataire>>> getLocataires({
    required int page,
    String? recherche,
  });
  Future<Either<Failure, Locataire>> getLocataire(String id);

  /// Création avec une clé d'idempotence par formulaire : un renvoi après
  /// coupure réseau ne crée pas de doublon.
  Future<Either<Failure, LocataireCree>> creerLocataire(
    Map<String, dynamic> data, {
    required String cle,
  });
  Future<Either<Failure, Locataire>> modifierLocataire(
    String id,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> supprimerLocataire(String id);
  Future<Either<Failure, Invitation>> inviterLocataire(String id);
  Future<Either<Failure, void>> enregistrerConsentementWhatsapp(
    String id, {
    required bool accorde,
  });
}
