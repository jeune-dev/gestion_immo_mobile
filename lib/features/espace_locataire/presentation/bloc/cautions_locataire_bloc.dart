import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/contester_retenue.dart';
import '../../domain/usecases/get_mes_cautions.dart';
import 'cautions_locataire_event.dart';
import 'cautions_locataire_state.dart';

/// Ma caution (§ 55) : montants et contestation d'une retenue.
class CautionsLocataireBloc
    extends Bloc<CautionsLocataireEvent, CautionsLocataireState> {
  final GetMesCautions getMesCautions;
  final ContesterRetenue contesterRetenue;

  CautionsLocataireBloc({
    required this.getMesCautions,
    required this.contesterRetenue,
  }) : super(CautionsLocataireInitial()) {
    on<LoadCautionsLocataire>(_onLoadCautionsLocataire);
    on<RafraichirCautionsLocataire>(_onRafraichirCautionsLocataire);
    on<ContesterRetenueEvent>(_onContesterRetenue);
    on<ResetCautionsLocataireState>(
        (_, emit) => emit(CautionsLocataireInitial()));
  }

  Future<void> _onLoadCautionsLocataire(
    LoadCautionsLocataire event,
    Emitter<CautionsLocataireState> emit,
  ) async {
    emit(CautionsLocataireLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirCautionsLocataire(
    RafraichirCautionsLocataire event,
    Emitter<CautionsLocataireState> emit,
  ) async {
    await _relire(emit);
  }

  Future<void> _onContesterRetenue(
    ContesterRetenueEvent event,
    Emitter<CautionsLocataireState> emit,
  ) async {
    final result = await contesterRetenue(event.mouvementId, event.message);
    await result.fold(
      (failure) async => emit(CautionsLocataireActionError(failure)),
      (_) async {
        emit(CautionsLocataireSuccess(message: 'Contestation envoyée'));
        await _relire(emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<CautionsLocataireState> emit) async {
    final dejaAffichee = state is! CautionsLocataireInitial &&
        state is! CautionsLocataireLoading &&
        state is! CautionsLocataireError;
    final result = await getMesCautions();
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? CautionsLocataireActionError(failure)
            : CautionsLocataireError(failure),
      ),
      (cautions) => emit(CautionsLocataireLoaded(cautions)),
    );
  }
}
