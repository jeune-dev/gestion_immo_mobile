import 'dart:typed_data';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/etat_des_lieux_model.dart';

abstract class EtatDesLieuxRemoteDataSource {
  Future<PageResultat<EtatDesLieuxModel>> getEtatsDesLieux({required int page});
  Future<EtatDesLieuxModel> getEtatDesLieux(String id);
  Future<EtatDesLieuxModel> creerEtatDesLieux(Map<String, dynamic> corps,
      {required String cle});
  Future<void> modifierEtatDesLieux(String id, Map<String, dynamic> corps);
  Future<void> supprimerEtatDesLieux(String id);
  Future<void> enregistrerSaisie(
      String id, List<Map<String, dynamic>> elements);
  Future<void> ajouterPiece(String id, Map<String, dynamic> corps);
  Future<void> modifierPiece(
      String id, String pieceId, Map<String, dynamic> corps);
  Future<void> supprimerPiece(String id, String pieceId);
  Future<void> ajouterElement(
      String id, String pieceId, Map<String, dynamic> corps);
  Future<void> modifierElement(
      String id, String elementId, Map<String, dynamic> corps);
  Future<void> supprimerElement(String id, String elementId);
  Future<void> ajouterPhoto(String id, String elementId, String chemin);
  Future<void> supprimerPhoto(String id, String photoId);
  Future<void> soumettre(String id);

  /// Nouvelle version (brouillon) d'un état des lieux accepté ou contesté.
  Future<EtatDesLieuxModel> corriger(String id);
  Future<Uint8List> pdf(String id);
  Future<ComparaisonEdlModel> comparaison(String bailId);
}

class EtatDesLieuxRemoteDataSourceImpl implements EtatDesLieuxRemoteDataSource {
  final ApiClient api;
  EtatDesLieuxRemoteDataSourceImpl({required this.api});

  EtatDesLieuxModel _edl(Map<String, dynamic> r) => EtatDesLieuxModel.fromJson(
      Map<String, dynamic>.from(r['inspection'] as Map));

  @override
  Future<PageResultat<EtatDesLieuxModel>> getEtatsDesLieux(
          {required int page}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.etatsDesLieux,
            query: {'page': page, 'tri': '-created_at'}),
        EtatDesLieuxModel.fromJson,
      );

  @override
  Future<EtatDesLieuxModel> getEtatDesLieux(String id) async =>
      _edl(await api.get<Map<String, dynamic>>(ApiEndpoints.etatDesLieux(id)));

  @override
  Future<EtatDesLieuxModel> creerEtatDesLieux(Map<String, dynamic> corps,
          {required String cle}) async =>
      _edl(await api.post<Map<String, dynamic>>(ApiEndpoints.etatsDesLieux,
          body: {...corps, 'client_reference': 'edl-$cle'}, idempotence: cle));

  @override
  Future<void> modifierEtatDesLieux(String id, Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.etatDesLieux(id), body: corps);

  @override
  Future<void> supprimerEtatDesLieux(String id) =>
      api.delete<dynamic>(ApiEndpoints.etatDesLieux(id));

  @override
  Future<void> enregistrerSaisie(
          String id, List<Map<String, dynamic>> elements) =>
      api.put<dynamic>(ApiEndpoints.etatDesLieuxSaisie(id),
          body: {'items': elements});

  @override
  Future<void> ajouterPiece(String id, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.etatDesLieuxPieces(id), body: corps);

  @override
  Future<void> modifierPiece(
          String id, String pieceId, Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.etatDesLieuxPiece(id, pieceId),
          body: corps);

  @override
  Future<void> supprimerPiece(String id, String pieceId) =>
      api.delete<dynamic>(ApiEndpoints.etatDesLieuxPiece(id, pieceId));

  @override
  Future<void> ajouterElement(
          String id, String pieceId, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.etatDesLieuxElements(id, pieceId),
          body: corps);

  @override
  Future<void> modifierElement(
          String id, String elementId, Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.etatDesLieuxElement(id, elementId),
          body: corps);

  @override
  Future<void> supprimerElement(String id, String elementId) =>
      api.delete<dynamic>(ApiEndpoints.etatDesLieuxElement(id, elementId));

  /// Horodatage de la prise de vue ET horodatage serveur conservés (§ 52.4).
  @override
  Future<void> ajouterPhoto(String id, String elementId, String chemin) =>
      api.upload<dynamic>(
        ApiEndpoints.etatDesLieuxElementPhotos(id, elementId),
        cheminFichier: chemin,
        champs: {'captured_at': DateTime.now().toUtc().toIso8601String()},
        idempotence: nouvelleCle(),
      );

  @override
  Future<void> supprimerPhoto(String id, String photoId) =>
      api.delete<dynamic>(ApiEndpoints.etatDesLieuxPhoto(id, photoId));

  @override
  Future<void> soumettre(String id) =>
      api.post<dynamic>(ApiEndpoints.etatDesLieuxSoumettre(id));

  @override
  Future<EtatDesLieuxModel> corriger(String id) async =>
      _edl(await api.post<Map<String, dynamic>>(
          ApiEndpoints.etatDesLieuxCorriger(id),
          idempotence: nouvelleCle()));

  @override
  Future<Uint8List> pdf(String id) =>
      api.telecharger(ApiEndpoints.etatDesLieuxPdf(id));

  @override
  Future<ComparaisonEdlModel> comparaison(String bailId) async {
    final r = await api.get<Map<String, dynamic>>(
        ApiEndpoints.etatsDesLieuxComparaison,
        query: {'lease_id': bailId});
    return ComparaisonEdlModel.fromJson(
        Map<String, dynamic>.from(r['comparaison'] as Map));
  }
}
