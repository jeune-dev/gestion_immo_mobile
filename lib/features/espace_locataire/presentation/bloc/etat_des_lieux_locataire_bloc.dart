import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/accepter_etat_des_lieux.dart';
import '../../domain/usecases/contester_etat_des_lieux.dart';
import '../../domain/usecases/get_mon_etat_des_lieux.dart';
import 'etat_des_lieux_locataire_event.dart';
import 'etat_des_lieux_locataire_state.dart';

/// État des lieux côté locataire : consulter, accepter ou contester dans
/// le délai (§ 52).
class EtatDesLieuxLocataireBloc
    extends Bloc<EtatDesLieuxLocataireEvent, EtatDesLieuxLocataireState> {
  final GetMonEtatDesLieux getMonEtatDesLieux;
  final AccepterEtatDesLieux accepterEtatDesLieux;
  final ContesterEtatDesLieux contesterEtatDesLieux;

  EtatDesLieuxLocataireBloc({
    required this.getMonEtatDesLieux,
    required this.accepterEtatDesLieux,
    required this.contesterEtatDesLieux,
  }) : super(EtatDesLieuxLocataireInitial()) {
    on<LoadEtatDesLieuxLocataire>(_onLoadEtatDesLieuxLocataire);
    on<RafraichirEtatDesLieuxLocataire>(_onRafraichirEtatDesLieuxLocataire);
    on<AccepterEtatDesLieuxEvent>(_onAccepterEtatDesLieux);
    on<ContesterEtatDesLieuxEvent>(_onContesterEtatDesLieux);
    on<ResetEtatDesLieuxLocataireState>(
        (_, emit) => emit(EtatDesLieuxLocataireInitial()));
  }

  Future<void> _onLoadEtatDesLieuxLocataire(
    LoadEtatDesLieuxLocataire event,
    Emitter<EtatDesLieuxLocataireState> emit,
  ) async {
    emit(EtatDesLieuxLocataireLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirEtatDesLieuxLocataire(
    RafraichirEtatDesLieuxLocataire event,
    Emitter<EtatDesLieuxLocataireState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onAccepterEtatDesLieux(
    AccepterEtatDesLieuxEvent event,
    Emitter<EtatDesLieuxLocataireState> emit,
  ) async {
    final result = await accepterEtatDesLieux(event.id);
    await result.fold(
      (failure) async => emit(EtatDesLieuxLocataireActionError(failure)),
      (_) async {
        emit(EtatDesLieuxLocataireSuccess(message: 'État des lieux accepté'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onContesterEtatDesLieux(
    ContesterEtatDesLieuxEvent event,
    Emitter<EtatDesLieuxLocataireState> emit,
  ) async {
    final result = await contesterEtatDesLieux(event.id, event.commentaire);
    await result.fold(
      (failure) async => emit(EtatDesLieuxLocataireActionError(failure)),
      (_) async {
        emit(EtatDesLieuxLocataireSuccess(message: 'Contestation envoyée'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(
      String id, Emitter<EtatDesLieuxLocataireState> emit) async {
    final dejaAffichee = state is! EtatDesLieuxLocataireInitial &&
        state is! EtatDesLieuxLocataireLoading &&
        state is! EtatDesLieuxLocataireError;
    final result = await getMonEtatDesLieux(id);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? EtatDesLieuxLocataireActionError(failure)
            : EtatDesLieuxLocataireError(failure),
      ),
      (etatDesLieux) => emit(EtatDesLieuxLocataireLoaded(etatDesLieux)),
    );
  }
}
