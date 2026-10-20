import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../../domain/usecases/ajouter_photo_document.dart';
import '../../domain/usecases/changer_visibilite_document.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/get_lien_document.dart';
import '../../domain/usecases/supprimer_document.dart';
import 'documents_event.dart';
import 'documents_state.dart';

/// Documents et photos rattachés à une entité (immeuble, appartement,
/// locataire, bail, artisan…).
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final GetDocuments getDocuments;
  final AjouterPhotoDocument ajouterPhotoDocument;
  final ChangerVisibiliteDocument changerVisibiliteDocument;
  final SupprimerDocument supprimerDocument;
  final GetLienDocument getLienDocument;

  DocumentsBloc({
    required this.getDocuments,
    required this.ajouterPhotoDocument,
    required this.changerVisibiliteDocument,
    required this.supprimerDocument,
    required this.getLienDocument,
  }) : super(DocumentsInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<AjouterPhotoDocumentEvent>(_onAjouterPhotoDocument);
    on<ChangerVisibiliteDocumentEvent>(_onChangerVisibiliteDocument);
    on<SupprimerDocumentEvent>(_onSupprimerDocument);
    on<GetLienDocumentEvent>(_onGetLienDocument);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentsState> emit,
  ) async {
    await _charger(event.type, event.id, emit);
  }

  Future<void> _onAjouterPhotoDocument(
    AjouterPhotoDocumentEvent event,
    Emitter<DocumentsState> emit,
  ) async {
    await _agir(
      event.type,
      event.id,
      emit,
      ajouterPhotoDocument(
          type: event.type, id: event.id, chemin: event.chemin),
      'Photo ajoutée',
    );
  }

  Future<void> _onChangerVisibiliteDocument(
    ChangerVisibiliteDocumentEvent event,
    Emitter<DocumentsState> emit,
  ) async {
    await _agir(
      event.type,
      event.id,
      emit,
      changerVisibiliteDocument(event.documentId, visible: event.visible),
      event.visible
          ? 'Document partagé avec le locataire'
          : 'Document retiré du partage',
    );
  }

  Future<void> _onSupprimerDocument(
    SupprimerDocumentEvent event,
    Emitter<DocumentsState> emit,
  ) async {
    await _agir(
      event.type,
      event.id,
      emit,
      supprimerDocument(event.documentId),
      'Document supprimé',
    );
  }

  Future<void> _onGetLienDocument(
    GetLienDocumentEvent event,
    Emitter<DocumentsState> emit,
  ) async {
    final result = await getLienDocument(event.documentId);
    result.fold(
      (failure) => emit(DocumentsError(failure)),
      (lien) => emit(LienDocumentLoaded(lien)),
    );
  }

  /// Exécute une action puis, si elle réussit, affiche [message] et relit la
  /// liste.
  Future<void> _agir(
    String type,
    String id,
    Emitter<DocumentsState> emit,
    Future<Either<Failure, void>> action,
    String message,
  ) async {
    final result = await action;
    await result.fold(
      (failure) async => emit(DocumentsError(failure)),
      (_) async {
        emit(DocumentsSuccess(message: message));
        await _charger(type, id, emit);
      },
    );
  }

  Future<void> _charger(
    String type,
    String id,
    Emitter<DocumentsState> emit,
  ) async {
    final result = await getDocuments(type: type, id: id);
    result.fold(
      (failure) => emit(DocumentsError(failure)),
      (page) => emit(DocumentsLoaded(page.items)),
    );
  }
}
