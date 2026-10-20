import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/demander_reinitialisation.dart';
import '../../domain/usecases/reinitialiser_mot_de_passe.dart';
import 'mot_de_passe_oublie_event.dart';
import 'mot_de_passe_oublie_state.dart';

/// Mot de passe oublié : code à 6 chiffres envoyé, puis nouveau mot de passe.
class MotDePasseOublieBloc
    extends Bloc<MotDePasseOublieEvent, MotDePasseOublieState> {
  final DemanderReinitialisation demanderReinitialisation;
  final ReinitialiserMotDePasse reinitialiserMotDePasse;

  MotDePasseOublieBloc({
    required this.demanderReinitialisation,
    required this.reinitialiserMotDePasse,
  }) : super(MotDePasseOublieInitial()) {
    on<EnvoyerCodeEvent>(_onEnvoyerCode);
    on<ReinitialiserMotDePasseEvent>(_onReinitialiserMotDePasse);
    on<RecommencerReinitialisation>(
      (_, emit) => emit(MotDePasseOublieInitial()),
    );
  }

  Future<void> _onEnvoyerCode(
    EnvoyerCodeEvent event,
    Emitter<MotDePasseOublieState> emit,
  ) async {
    emit(MotDePasseOublieLoading(state.etape));
    final result = await demanderReinitialisation(event.identifiant);
    result.fold(
      (failure) => emit(
        MotDePasseOublieError(EtapeReinitialisation.identifiant, failure),
      ),
      (_) => emit(CodeEnvoye()),
    );
  }

  Future<void> _onReinitialiserMotDePasse(
    ReinitialiserMotDePasseEvent event,
    Emitter<MotDePasseOublieState> emit,
  ) async {
    emit(MotDePasseOublieLoading(state.etape));
    final result = await reinitialiserMotDePasse({
      'identifiant': event.identifiant.trim(),
      'code': event.code.trim(),
      'password': event.motDePasse,
      'password_confirmation': event.confirmation,
    });
    result.fold(
      (failure) => emit(
        MotDePasseOublieError(EtapeReinitialisation.code, failure),
      ),
      (_) => emit(MotDePasseReinitialise()),
    );
  }
}
