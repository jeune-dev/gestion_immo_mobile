import '../../domain/entities/document_app.dart';

class DocumentModel extends DocumentApp {
  const DocumentModel(
      {required super.id,
      super.categorie,
      super.mimeType,
      super.nomOrigine,
      super.aMiniature,
      super.visibleLocataire,
      super.creeLe});

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: '${json['id']}',
        categorie: json['category'] as String?,
        mimeType: json['mime_type'] as String?,
        nomOrigine: json['original_name'] as String?,
        aMiniature: json['has_thumbnail'] == true,
        visibleLocataire: json['visible_to_tenant'] == true,
        creeLe: json['created_at'] as String?,
      );

  /// Document imbriqué dans une autre ressource (photo de travaux, pièce d'incident…).
  static DocumentModel? depuis(dynamic json) => json is Map
      ? DocumentModel.fromJson(Map<String, dynamic>.from(json))
      : null;
}

class LienDocumentModel extends LienDocument {
  const LienDocumentModel({required super.url, super.expireDansSecondes});

  factory LienDocumentModel.fromJson(Map<String, dynamic> json) =>
      LienDocumentModel(
          url: '${json['url'] ?? ''}',
          expireDansSecondes: (json['expires_in'] as num?)?.toInt());
}
