import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'rapport_event.dart';
import 'rapport_state.dart';

/// Un onglet de rapport : lecture du rapport de la période via son cas
/// d'usage (financier, immobilier, locataires, travaux).
class RapportBloc<T> extends Bloc<RapportEvent, RapportState> {
  final Future<Either<Failure, T>> Function() lireRapport;

  RapportBloc({required this.lireRapport}) : super(RapportInitial()) {
    on<LoadRapport>(_onLoadRapport);
    on<RafraichirRapport>(_onRafraichirRapport);
  }

  Future<void> _onLoadRapport(
    LoadRapport event,
    Emitter<RapportState> emit,
  ) async {
    emit(RapportLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirRapport(
    RafraichirRapport event,
    Emitter<RapportState> emit,
  ) async {
    await _relire(emit);
  }

  /// Relit le rapport. S'il est déjà affiché, un échec de relecture n'efface
  /// pas l'écran.
  Future<void> _relire(Emitter<RapportState> emit) async {
    final dejaAffiche = state is RapportLoaded<T>;
    final result = await lireRapport();
    result.fold(
      (failure) => emit(
        dejaAffiche ? RapportActionError(failure) : RapportError(failure),
      ),
      (rapport) => emit(RapportLoaded<T>(rapport)),
    );
  }
}
