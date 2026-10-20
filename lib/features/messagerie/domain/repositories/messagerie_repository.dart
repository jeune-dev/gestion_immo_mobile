import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/messagerie.dart';

abstract class MessagerieRepository {
  Future<Either<Failure, PageResultat<FilDiscussion>>> fils(
      {required int page, required bool espaceLocataire});

  /// Fil existant avec ce locataire (côté propriétaire), ou `null`.
  Future<Either<Failure, String?>> filAvecLocataire(String locataireId);
  Future<Either<Failure, List<Message>>> messages(String filId,
      {required bool espaceLocataire});
  Future<Either<Failure, void>> marquerLu(String filId,
      {required bool espaceLocataire});
  Future<Either<Failure, Message>> envoyerTexte(String texte,
      {String? filId, String? locataireId});
  Future<Either<Failure, Message>> envoyerPhoto(String chemin,
      {String? filId, String? locataireId});
}
