import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_comparaison_edl.dart';
import 'comparaison_event.dart';
import 'comparaison_state.dart';

/// Comparaison entrée / sortie d'un bail (§ 52.3).
class ComparaisonBloc extends Bloc<ComparaisonEvent, ComparaisonState> {
  final GetComparaisonEdl getComparaisonEdl;

  ComparaisonBloc({
    required this.getComparaisonEdl,
  }) : super(ComparaisonInitial()) {
    on<LoadComparaison>(_onLoadComparaison);
    on<RafraichirComparaison>(_onRafraichirComparaison);
    on<ResetComparaisonState>((_, emit) => emit(ComparaisonInitial()));
  }

  Future<void> _onLoadComparaison(
    LoadComparaison event,
    Emitter<ComparaisonState> emit,
  ) async {
    emit(ComparaisonLoading());
    await _relire(event.bailId, emit);
  }

  Future<void> _onRafraichirComparaison(
    RafraichirComparaison event,
    Emitter<ComparaisonState> emit,
  ) async {
    await _relire(event.bailId, emit);
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String bailId, Emitter<ComparaisonState> emit) async {
    final dejaAffichee = state is! ComparaisonInitial &&
        state is! ComparaisonLoading &&
        state is! ComparaisonError;
    final result = await getComparaisonEdl(bailId);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? ComparaisonActionError(failure)
            : ComparaisonError(failure),
      ),
      (comparaison) => emit(ComparaisonLoaded(comparaison)),
    );
  }
}
