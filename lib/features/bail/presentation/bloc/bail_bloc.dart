import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/activer_bail.dart';
import '../../domain/usecases/annuler_bail.dart';
import '../../domain/usecases/cloturer_bail.dart';
import '../../domain/usecases/get_fiche_bail.dart';
import 'bail_event.dart';
import 'bail_state.dart';

/// Fiche d'un bail : activation, annulation et clôture.
class BailBloc extends Bloc<BailEvent, BailState> {
  final GetFicheBail getFicheBail;
  final ActiverBail activerBail;
  final AnnulerBail annulerBail;
  final CloturerBail cloturerBail;

  BailBloc({
    required this.getFicheBail,
    required this.activerBail,
    required this.annulerBail,
    required this.cloturerBail,
  }) : super(BailInitial()) {
    on<LoadBail>(_onLoadBail);
    on<RafraichirBail>(_onRafraichirBail);
    on<ActiverBailEvent>(_onActiverBail);
    on<AnnulerBailEvent>(_onAnnulerBail);
    on<CloturerBailEvent>(_onCloturerBail);
    on<ResetBailState>((_, emit) => emit(BailInitial()));
  }

  Future<void> _onLoadBail(
    LoadBail event,
    Emitter<BailState> emit,
  ) async {
    emit(BailLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirBail(
    RafraichirBail event,
    Emitter<BailState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onActiverBail(
    ActiverBailEvent event,
    Emitter<BailState> emit,
  ) async {
    final result = await activerBail(event.id);
    await result.fold(
      (failure) async => emit(BailActionError(failure)),
      (messages) async {
        if (messages.isNotEmpty) emit(AvertissementsActivationLoaded(messages));
        emit(BailSuccess(message: 'Bail activé'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onAnnulerBail(
    AnnulerBailEvent event,
    Emitter<BailState> emit,
  ) async {
    final result = await annulerBail(event.id, event.motif);
    await result.fold(
      (failure) async => emit(BailActionError(failure)),
      (_) async {
        emit(BailSuccess(message: 'Bail annulé'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onCloturerBail(
    CloturerBailEvent event,
    Emitter<BailState> emit,
  ) async {
    final result = await cloturerBail(event.id);
    await result.fold(
      (failure) async => emit(BailActionError(failure)),
      (_) async {
        emit(BailSuccess(message: 'Bail clôturé'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<BailState> emit) async {
    final dejaAffichee =
        state is! BailInitial && state is! BailLoading && state is! BailError;
    final result = await getFicheBail(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? BailActionError(failure) : BailError(failure),
      ),
      (fiche) => emit(BailLoaded(fiche)),
    );
  }
}
