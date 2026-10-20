import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_moyens_paiement.dart';
import 'moyens_paiement_event.dart';
import 'moyens_paiement_state.dart';

/// Moyens de paiement du propriétaire (§ 51.5).
class MoyensPaiementBloc
    extends Bloc<MoyensPaiementEvent, MoyensPaiementState> {
  final GetMoyensPaiement getMoyensPaiement;

  MoyensPaiementBloc({
    required this.getMoyensPaiement,
  }) : super(MoyensPaiementInitial()) {
    on<LoadMoyensPaiement>(_onLoadMoyensPaiement);
    on<RafraichirMoyensPaiement>(_onRafraichirMoyensPaiement);
    on<ResetMoyensPaiementState>((_, emit) => emit(MoyensPaiementInitial()));
  }

  Future<void> _onLoadMoyensPaiement(
    LoadMoyensPaiement event,
    Emitter<MoyensPaiementState> emit,
  ) async {
    emit(MoyensPaiementLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirMoyensPaiement(
    RafraichirMoyensPaiement event,
    Emitter<MoyensPaiementState> emit,
  ) async {
    await _relire(emit);
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<MoyensPaiementState> emit) async {
    final dejaAffichee = state is! MoyensPaiementInitial &&
        state is! MoyensPaiementLoading &&
        state is! MoyensPaiementError;
    final result = await getMoyensPaiement();
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? MoyensPaiementActionError(failure)
            : MoyensPaiementError(failure),
      ),
      (moyens) => emit(MoyensPaiementLoaded(moyens)),
    );
  }
}
