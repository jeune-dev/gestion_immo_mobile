import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_parametres.dart';
import '../../domain/usecases/modifier_reglages.dart';
import 'parametres_event.dart';
import 'parametres_state.dart';

/// Règles de gestion du propriétaire.
class ParametresBloc extends Bloc<ParametresEvent, ParametresState> {
  final GetParametres getParametres;
  final ModifierReglages modifierReglages;

  ParametresBloc({
    required this.getParametres,
    required this.modifierReglages,
  }) : super(ParametresInitial()) {
    on<LoadParametres>(_onLoadParametres);
    on<RafraichirParametres>(_onRafraichirParametres);
    on<ModifierReglagesEvent>(_onModifierReglages);
    on<ResetParametresState>((_, emit) => emit(ParametresInitial()));
  }

  Future<void> _onLoadParametres(
    LoadParametres event,
    Emitter<ParametresState> emit,
  ) async {
    emit(ParametresLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirParametres(
    RafraichirParametres event,
    Emitter<ParametresState> emit,
  ) async {
    await _relire(emit);
  }

  Future<void> _onModifierReglages(
    ModifierReglagesEvent event,
    Emitter<ParametresState> emit,
  ) async {
    final result = await modifierReglages(event.data);
    await result.fold(
      (failure) async => emit(ParametresActionError(failure)),
      (_) async {
        emit(ParametresSuccess(message: 'Paramètre enregistré'));
        await _relire(emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<ParametresState> emit) async {
    final dejaAffichee = state is! ParametresInitial &&
        state is! ParametresLoading &&
        state is! ParametresError;
    final result = await getParametres();
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? ParametresActionError(failure)
            : ParametresError(failure),
      ),
      (parametres) => emit(ParametresLoaded(parametres)),
    );
  }
}
