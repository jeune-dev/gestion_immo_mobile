import 'dart:typed_data';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/document_model.dart';

abstract class DocumentsRemoteDataSource {
  Future<PageResultat<DocumentModel>> getDocuments(
      {required String type, required String id});
  Future<void> ajouterPhoto(
      {required String type, required String id, required String chemin});
  Future<Uint8List> telecharger(String id, {String? taille});
  Future<LienDocumentModel> lien(String id);
  Future<void> changerVisibilite(String id, {required bool visible});
  Future<void> supprimerDocument(String id);
}

class DocumentsRemoteDataSourceImpl implements DocumentsRemoteDataSource {
  final ApiClient api;
  DocumentsRemoteDataSourceImpl({required this.api});

  @override
  Future<PageResultat<DocumentModel>> getDocuments(
          {required String type, required String id}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.documents,
            query: {'entity_type': type, 'entity_id': id, 'limit': 50}),
        DocumentModel.fromJson,
      );

  @override
  Future<void> ajouterPhoto(
          {required String type, required String id, required String chemin}) =>
      api.upload<dynamic>(
        ApiEndpoints.documents,
        cheminFichier: chemin,
        champs: {
          'entity_type': type,
          'entity_id': id,
          'category': 'photo',
          'captured_at': DateTime.now().toUtc().toIso8601String()
        },
        idempotence: nouvelleCle(),
      );

  @override
  Future<Uint8List> telecharger(String id, {String? taille}) =>
      api.telecharger(ApiEndpoints.documentFichier(id),
          query: {if (taille != null) 'taille': taille});

  @override
  Future<LienDocumentModel> lien(String id) async => LienDocumentModel.fromJson(
      await api.get<Map<String, dynamic>>(ApiEndpoints.documentLien(id),
          cache: false));

  @override
  Future<void> changerVisibilite(String id, {required bool visible}) =>
      api.patch<dynamic>(ApiEndpoints.document(id),
          body: {'visible_to_tenant': visible});

  @override
  Future<void> supprimerDocument(String id) =>
      api.delete<dynamic>(ApiEndpoints.document(id));
}
