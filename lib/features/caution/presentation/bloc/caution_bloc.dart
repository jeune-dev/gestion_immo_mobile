import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_caution.dart';
import 'caution_event.dart';
import 'caution_state.dart';

/// Fiche d'une caution ; versements, retenues et restitutions passent par
/// des formulaires puis relisent la fiche.
class CautionBloc extends Bloc<CautionEvent, CautionState> {
  final GetCaution getCaution;

  CautionBloc({
    required this.getCaution,
  }) : super(CautionInitial()) {
    on<LoadCaution>(_onLoadCaution);
    on<RafraichirCaution>(_onRafraichirCaution);
    on<ResetCautionState>((_, emit) => emit(CautionInitial()));
  }

  Future<void> _onLoadCaution(
    LoadCaution event,
    Emitter<CautionState> emit,
  ) async {
    emit(CautionLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirCaution(
    RafraichirCaution event,
    Emitter<CautionState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<CautionState> emit) async {
    final dejaAffichee = state is! CautionInitial &&
        state is! CautionLoading &&
        state is! CautionError;
    final result = await getCaution(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? CautionActionError(failure) : CautionError(failure),
      ),
      (caution) => emit(CautionLoaded(caution)),
    );
  }
}
