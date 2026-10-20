import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/ajouter_piece_signalement.dart';
import '../../domain/usecases/get_mon_incident.dart';
import 'incident_locataire_event.dart';
import 'incident_locataire_state.dart';

/// Suivi d'un problème signalé par le locataire.
class IncidentLocataireBloc
    extends Bloc<IncidentLocataireEvent, IncidentLocataireState> {
  final GetMonIncident getMonIncident;
  final AjouterPieceSignalement ajouterPieceSignalement;

  IncidentLocataireBloc({
    required this.getMonIncident,
    required this.ajouterPieceSignalement,
  }) : super(IncidentLocataireInitial()) {
    on<LoadIncidentLocataire>(_onLoadIncidentLocataire);
    on<RafraichirIncidentLocataire>(_onRafraichirIncidentLocataire);
    on<AjouterPieceSignalementEvent>(_onAjouterPieceSignalement);
    on<ResetIncidentLocataireState>(
        (_, emit) => emit(IncidentLocataireInitial()));
  }

  Future<void> _onLoadIncidentLocataire(
    LoadIncidentLocataire event,
    Emitter<IncidentLocataireState> emit,
  ) async {
    emit(IncidentLocataireLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirIncidentLocataire(
    RafraichirIncidentLocataire event,
    Emitter<IncidentLocataireState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onAjouterPieceSignalement(
    AjouterPieceSignalementEvent event,
    Emitter<IncidentLocataireState> emit,
  ) async {
    final result = await ajouterPieceSignalement(event.id, event.chemin);
    await result.fold(
      (failure) async => emit(IncidentLocataireActionError(failure)),
      (_) async {
        emit(IncidentLocataireSuccess(
            message: event.video ? 'Vidéo ajoutée' : 'Photo ajoutée'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<IncidentLocataireState> emit) async {
    final dejaAffichee = state is! IncidentLocataireInitial &&
        state is! IncidentLocataireLoading &&
        state is! IncidentLocataireError;
    final result = await getMonIncident(id);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? IncidentLocataireActionError(failure)
            : IncidentLocataireError(failure),
      ),
      (incident) => emit(IncidentLocataireLoaded(incident)),
    );
  }
}
