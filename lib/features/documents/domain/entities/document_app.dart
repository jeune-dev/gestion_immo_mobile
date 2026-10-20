import 'package:equatable/equatable.dart';

/// Document ou photo stocké par l'API (`documents.versApi`).
class DocumentApp extends Equatable {
  final String id;
  final String? categorie;
  final String? mimeType;
  final String? nomOrigine;
  final bool aMiniature;
  final bool visibleLocataire;
  final String? creeLe;

  bool get estImage => (mimeType ?? '').startsWith('image/');

  const DocumentApp({
    required this.id,
    this.categorie,
    this.mimeType,
    this.nomOrigine,
    this.aMiniature = false,
    this.visibleLocataire = false,
    this.creeLe,
  });

  @override
  List<Object?> get props => [
        id,
        categorie,
        mimeType,
        nomOrigine,
        aMiniature,
        visibleLocataire,
        creeLe
      ];
}

/// Lien temporaire de partage (`GET /documents/:id/lien`).
class LienDocument extends Equatable {
  final String url;
  final int? expireDansSecondes;

  /// Stockage disque (développement) : URL relative, inutilisable hors de l'application.
  bool get partageable => url.startsWith('http');

  const LienDocument({required this.url, this.expireDansSecondes});

  @override
  List<Object?> get props => [url, expireDansSecondes];
}
