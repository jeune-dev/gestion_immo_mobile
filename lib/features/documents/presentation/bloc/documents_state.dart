import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';

abstract class DocumentsState {}

class DocumentsInitial extends DocumentsState {}

class DocumentsLoaded extends DocumentsState {
  final List<DocumentApp> documents;
  DocumentsLoaded(this.documents);
}

/// Échec d'une lecture ou d'une action : un message ponctuel.
class DocumentsError extends DocumentsState {
  final Failure failure;
  DocumentsError(this.failure);

  String get message => failure.messageComplet;
}

class DocumentsSuccess extends DocumentsState {
  final String message;
  DocumentsSuccess({this.message = 'Opération réussie'});
}

/// Lien temporaire à partager.
class LienDocumentLoaded extends DocumentsState {
  final LienDocument lien;
  LienDocumentLoaded(this.lien);
}
