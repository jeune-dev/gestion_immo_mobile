abstract class DocumentsEvent {}

/// Documents rattachés à une entité ([type] : immeuble, appartement,
/// locataire, bail, artisan… ; [id] : l'entité).
class LoadDocuments extends DocumentsEvent {
  final String type;
  final String id;
  LoadDocuments(this.type, this.id);
}

class AjouterPhotoDocumentEvent extends DocumentsEvent {
  final String type;
  final String id;
  final String chemin;
  AjouterPhotoDocumentEvent(this.type, this.id, this.chemin);
}

class ChangerVisibiliteDocumentEvent extends DocumentsEvent {
  final String type;
  final String id;
  final String documentId;
  final bool visible;
  ChangerVisibiliteDocumentEvent(
      this.type, this.id, this.documentId, this.visible);
}

class SupprimerDocumentEvent extends DocumentsEvent {
  final String type;
  final String id;
  final String documentId;
  SupprimerDocumentEvent(this.type, this.id, this.documentId);
}

/// Lien temporaire de partage d'un document.
class GetLienDocumentEvent extends DocumentsEvent {
  final String documentId;
  GetLienDocumentEvent(this.documentId);
}
