import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/changer_statut_appartement.dart';
import '../../domain/usecases/get_fiche_appartement.dart';
import '../../domain/usecases/supprimer_appartement.dart';
import 'appartement_event.dart';
import 'appartement_state.dart';

/// Fiche d'un appartement : bail en cours, rentabilité, historique.
class AppartementBloc extends Bloc<AppartementEvent, AppartementState> {
  final GetFicheAppartement getFicheAppartement;
  final ChangerStatutAppartement changerStatutAppartement;
  final SupprimerAppartement supprimerAppartement;

  /// Rentabilité de l'année civile en cours.
  final int annee = DateTime.now().year;

  AppartementBloc({
    required this.getFicheAppartement,
    required this.changerStatutAppartement,
    required this.supprimerAppartement,
  }) : super(AppartementInitial()) {
    on<LoadAppartement>(_onLoadAppartement);
    on<RafraichirAppartement>(_onRafraichirAppartement);
    on<ChangerStatutAppartementEvent>(_onChangerStatutAppartement);
    on<SupprimerAppartementEvent>(_onSupprimerAppartement);
    on<ResetAppartementState>((_, emit) => emit(AppartementInitial()));
  }

  Future<void> _onLoadAppartement(
    LoadAppartement event,
    Emitter<AppartementState> emit,
  ) async {
    emit(AppartementLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirAppartement(
    RafraichirAppartement event,
    Emitter<AppartementState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onChangerStatutAppartement(
    ChangerStatutAppartementEvent event,
    Emitter<AppartementState> emit,
  ) async {
    final result = await changerStatutAppartement(event.id, event.statut);
    await result.fold(
      (failure) async => emit(AppartementActionError(failure)),
      (_) async {
        emit(AppartementSuccess(message: 'Statut modifié'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerAppartement(
    SupprimerAppartementEvent event,
    Emitter<AppartementState> emit,
  ) async {
    final result = await supprimerAppartement(event.id);
    result.fold(
      (failure) => emit(AppartementActionError(failure)),
      (_) => emit(AppartementSupprime()),
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<AppartementState> emit) async {
    final dejaAffichee = state is! AppartementInitial &&
        state is! AppartementLoading &&
        state is! AppartementError;
    final result = await getFicheAppartement(id, annee: annee);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? AppartementActionError(failure)
            : AppartementError(failure),
      ),
      (fiche) => emit(AppartementLoaded(fiche)),
    );
  }
}
