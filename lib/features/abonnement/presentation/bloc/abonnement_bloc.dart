import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_fiche_abonnement.dart';
import '../../domain/usecases/souscrire_abonnement.dart';
import 'abonnement_event.dart';
import 'abonnement_state.dart';

/// Abonnement du propriétaire : formule en cours et souscription.
class AbonnementBloc extends Bloc<AbonnementEvent, AbonnementState> {
  final GetFicheAbonnement getFicheAbonnement;
  final SouscrireAbonnement souscrireAbonnement;

  AbonnementBloc({
    required this.getFicheAbonnement,
    required this.souscrireAbonnement,
  }) : super(AbonnementInitial()) {
    on<LoadAbonnement>(_onLoadAbonnement);
    on<RafraichirAbonnement>(_onRafraichirAbonnement);
    on<SouscrireAbonnementEvent>(_onSouscrireAbonnement);
    on<ResetAbonnementState>((_, emit) => emit(AbonnementInitial()));
  }

  Future<void> _onLoadAbonnement(
    LoadAbonnement event,
    Emitter<AbonnementState> emit,
  ) async {
    emit(AbonnementLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirAbonnement(
    RafraichirAbonnement event,
    Emitter<AbonnementState> emit,
  ) async {
    await _relire(emit);
  }

  Future<void> _onSouscrireAbonnement(
    SouscrireAbonnementEvent event,
    Emitter<AbonnementState> emit,
  ) async {
    final result = await souscrireAbonnement(
      planCode: event.planCode,
      mois: event.mois,
      portefeuille: event.portefeuille,
    );
    await result.fold(
      (failure) async => emit(AbonnementActionError(failure)),
      (url) async {
        if (url != null) emit(LienPaiementAbonnementLoaded(url));
        await _relire(emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<AbonnementState> emit) async {
    final dejaAffichee = state is! AbonnementInitial &&
        state is! AbonnementLoading &&
        state is! AbonnementError;
    final result = await getFicheAbonnement();
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? AbonnementActionError(failure)
            : AbonnementError(failure),
      ),
      (fiche) => emit(AbonnementLoaded(fiche)),
    );
  }
}
