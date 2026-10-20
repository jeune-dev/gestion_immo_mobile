import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_immeuble.dart';
import '../../domain/usecases/supprimer_immeuble.dart';
import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/usecases/get_appartements.dart';
import 'immeuble_event.dart';
import 'immeuble_state.dart';

/// Fiche d'un immeuble : l'immeuble et ses appartements.
class ImmeubleBloc extends Bloc<ImmeubleEvent, ImmeubleState> {
  final GetImmeuble getImmeuble;
  final SupprimerImmeuble supprimerImmeuble;
  final GetAppartements getAppartements;

  ImmeubleBloc({
    required this.getImmeuble,
    required this.supprimerImmeuble,
    required this.getAppartements,
  }) : super(ImmeubleInitial()) {
    on<LoadImmeuble>(_onLoadImmeuble);
    on<RafraichirImmeuble>(_onRafraichirImmeuble);
    on<SupprimerImmeubleEvent>(_onSupprimerImmeuble);
    on<ResetImmeubleState>((_, emit) => emit(ImmeubleInitial()));
  }

  Future<void> _onLoadImmeuble(
    LoadImmeuble event,
    Emitter<ImmeubleState> emit,
  ) async {
    emit(ImmeubleLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirImmeuble(
    RafraichirImmeuble event,
    Emitter<ImmeubleState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onSupprimerImmeuble(
    SupprimerImmeubleEvent event,
    Emitter<ImmeubleState> emit,
  ) async {
    final result = await supprimerImmeuble(event.id);
    result.fold(
      (failure) => emit(ImmeubleActionError(failure)),
      (_) => emit(ImmeubleSupprime()),
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<ImmeubleState> emit) async {
    final dejaAffichee = state is! ImmeubleInitial &&
        state is! ImmeubleLoading &&
        state is! ImmeubleError;
    final result = await _lireFiche(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? ImmeubleActionError(failure) : ImmeubleError(failure),
      ),
      (fiche) => emit(ImmeubleLoaded(fiche)),
    );
  }

  /// L'immeuble et ses appartements, lus en parallèle.
  Future<Either<Failure, FicheImmeuble>> _lireFiche(String id) async {
    final result = await ensemble(
      getImmeuble(id),
      getAppartements(page: 1, immeubleId: id, limite: 100),
    );
    return result.map(
      (v) => (immeuble: v.$1, appartements: v.$2.items),
    );
  }
}
