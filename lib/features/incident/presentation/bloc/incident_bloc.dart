import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/analyser_incident.dart';
import '../../domain/usecases/get_incident.dart';
import '../../domain/usecases/rejeter_incident.dart';
import '../../domain/usecases/resoudre_incident.dart';
import 'incident_event.dart';
import 'incident_state.dart';

/// Traitement d'un incident (§ 23) : analyse, travaux, résolution ou rejet.
class IncidentBloc extends Bloc<IncidentEvent, IncidentState> {
  final GetIncident getIncident;
  final AnalyserIncident analyserIncident;
  final ResoudreIncident resoudreIncident;
  final RejeterIncident rejeterIncident;

  IncidentBloc({
    required this.getIncident,
    required this.analyserIncident,
    required this.resoudreIncident,
    required this.rejeterIncident,
  }) : super(IncidentInitial()) {
    on<LoadIncident>(_onLoadIncident);
    on<RafraichirIncident>(_onRafraichirIncident);
    on<AnalyserIncidentEvent>(_onAnalyserIncident);
    on<ResoudreIncidentEvent>(_onResoudreIncident);
    on<RejeterIncidentEvent>(_onRejeterIncident);
    on<ResetIncidentState>((_, emit) => emit(IncidentInitial()));
  }

  Future<void> _onLoadIncident(
    LoadIncident event,
    Emitter<IncidentState> emit,
  ) async {
    emit(IncidentLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirIncident(
    RafraichirIncident event,
    Emitter<IncidentState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onAnalyserIncident(
    AnalyserIncidentEvent event,
    Emitter<IncidentState> emit,
  ) async {
    final result = await analyserIncident(event.id, note: event.note);
    await result.fold(
      (failure) async => emit(IncidentActionError(failure)),
      (_) async {
        emit(IncidentSuccess(message: 'Incident en analyse'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onResoudreIncident(
    ResoudreIncidentEvent event,
    Emitter<IncidentState> emit,
  ) async {
    final result = await resoudreIncident(event.id, note: event.note);
    await result.fold(
      (failure) async => emit(IncidentActionError(failure)),
      (_) async {
        emit(IncidentSuccess(message: 'Incident résolu'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onRejeterIncident(
    RejeterIncidentEvent event,
    Emitter<IncidentState> emit,
  ) async {
    final result = await rejeterIncident(event.id, event.motif);
    await result.fold(
      (failure) async => emit(IncidentActionError(failure)),
      (_) async {
        emit(IncidentSuccess(message: 'Incident rejeté'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<IncidentState> emit) async {
    final dejaAffichee = state is! IncidentInitial &&
        state is! IncidentLoading &&
        state is! IncidentError;
    final result = await getIncident(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? IncidentActionError(failure) : IncidentError(failure),
      ),
      (incident) => emit(IncidentLoaded(incident)),
    );
  }
}
