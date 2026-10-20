import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/ajouter_photo_travaux.dart';
import '../../domain/usecases/get_travaux.dart';
import '../../domain/usecases/supprimer_photo_travaux.dart';
import 'travaux_event.dart';
import 'travaux_state.dart';

/// Fiche d'un chantier (§ 18–19).
class TravauxBloc extends Bloc<TravauxEvent, TravauxState> {
  final GetTravaux getTravaux;
  final AjouterPhotoTravaux ajouterPhotoTravaux;
  final SupprimerPhotoTravaux supprimerPhotoTravaux;

  TravauxBloc({
    required this.getTravaux,
    required this.ajouterPhotoTravaux,
    required this.supprimerPhotoTravaux,
  }) : super(TravauxInitial()) {
    on<LoadTravaux>(_onLoadTravaux);
    on<RafraichirTravaux>(_onRafraichirTravaux);
    on<AjouterPhotoTravauxEvent>(_onAjouterPhotoTravaux);
    on<SupprimerPhotoTravauxEvent>(_onSupprimerPhotoTravaux);
    on<ResetTravauxState>((_, emit) => emit(TravauxInitial()));
  }

  Future<void> _onLoadTravaux(
    LoadTravaux event,
    Emitter<TravauxState> emit,
  ) async {
    emit(TravauxLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirTravaux(
    RafraichirTravaux event,
    Emitter<TravauxState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onAjouterPhotoTravaux(
    AjouterPhotoTravauxEvent event,
    Emitter<TravauxState> emit,
  ) async {
    final result = await ajouterPhotoTravaux(
      event.id,
      phase: event.phase,
      chemin: event.chemin,
    );
    await result.fold(
      (failure) async => emit(TravauxActionError(failure)),
      (_) async {
        emit(TravauxSuccess(message: 'Photo ajoutée'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerPhotoTravaux(
    SupprimerPhotoTravauxEvent event,
    Emitter<TravauxState> emit,
  ) async {
    final result = await supprimerPhotoTravaux(event.id, event.photoId);
    await result.fold(
      (failure) async => emit(TravauxActionError(failure)),
      (_) async {
        emit(TravauxSuccess(message: 'Photo retirée'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<TravauxState> emit) async {
    final dejaAffichee = state is! TravauxInitial &&
        state is! TravauxLoading &&
        state is! TravauxError;
    final result = await getTravaux(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? TravauxActionError(failure) : TravauxError(failure),
      ),
      (travaux) => emit(TravauxLoaded(travaux)),
    );
  }
}
