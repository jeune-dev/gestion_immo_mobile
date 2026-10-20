import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_accueil_locataire.dart';
import 'accueil_locataire_event.dart';
import 'accueil_locataire_state.dart';

/// Accueil du locataire : ses logements et la prochaine échéance de chacun.
class AccueilLocataireBloc
    extends Bloc<AccueilLocataireEvent, AccueilLocataireState> {
  final GetAccueilLocataire getAccueilLocataire;

  AccueilLocataireBloc({
    required this.getAccueilLocataire,
  }) : super(AccueilLocataireInitial()) {
    on<LoadAccueilLocataire>(_onLoadAccueilLocataire);
    on<RafraichirAccueilLocataire>(_onRafraichirAccueilLocataire);
    on<ResetAccueilLocataireState>(
        (_, emit) => emit(AccueilLocataireInitial()));
  }

  Future<void> _onLoadAccueilLocataire(
    LoadAccueilLocataire event,
    Emitter<AccueilLocataireState> emit,
  ) async {
    emit(AccueilLocataireLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirAccueilLocataire(
    RafraichirAccueilLocataire event,
    Emitter<AccueilLocataireState> emit,
  ) async {
    await _relire(emit);
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<AccueilLocataireState> emit) async {
    final dejaAffichee = state is! AccueilLocataireInitial &&
        state is! AccueilLocataireLoading &&
        state is! AccueilLocataireError;
    final result = await getAccueilLocataire();
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? AccueilLocataireActionError(failure)
            : AccueilLocataireError(failure),
      ),
      (logements) => emit(AccueilLocataireLoaded(logements)),
    );
  }
}
