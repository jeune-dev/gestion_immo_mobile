import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_fiche_paiement.dart';
import 'paiement_event.dart';
import 'paiement_state.dart';

/// Fiche d'un paiement reçu (le remboursement passe par un formulaire puis
/// relit la fiche).
class PaiementBloc extends Bloc<PaiementEvent, PaiementState> {
  final GetFichePaiement getFichePaiement;

  PaiementBloc({
    required this.getFichePaiement,
  }) : super(PaiementInitial()) {
    on<LoadPaiement>(_onLoadPaiement);
    on<RafraichirPaiement>(_onRafraichirPaiement);
    on<ResetPaiementState>((_, emit) => emit(PaiementInitial()));
  }

  Future<void> _onLoadPaiement(
    LoadPaiement event,
    Emitter<PaiementState> emit,
  ) async {
    emit(PaiementLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirPaiement(
    RafraichirPaiement event,
    Emitter<PaiementState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<PaiementState> emit) async {
    final dejaAffichee = state is! PaiementInitial &&
        state is! PaiementLoading &&
        state is! PaiementError;
    final result = await getFichePaiement(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? PaiementActionError(failure) : PaiementError(failure),
      ),
      (fiche) => emit(PaiementLoaded(fiche)),
    );
  }
}
