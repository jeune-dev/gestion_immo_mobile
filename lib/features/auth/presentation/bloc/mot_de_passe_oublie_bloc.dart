import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/demander_reinitialisation.dart';
import '../../domain/usecases/reinitialiser_mot_de_passe.dart';
import '../../domain/usecases/verifier_code_reinitialisation.dart';
import 'mot_de_passe_oublie_event.dart';
import 'mot_de_passe_oublie_state.dart';

/// Mot de passe oublié en trois étapes (comme Yobante) : code envoyé par
/// e-mail, code vérifié, puis nouveau mot de passe.
class MotDePasseOublieBloc
    extends Bloc<MotDePasseOublieEvent, MotDePasseOublieState> {
  final DemanderReinitialisation demanderReinitialisation;
  final VerifierCodeReinitialisation verifierCode;
  final ReinitialiserMotDePasse reinitialiserMotDePasse;

  MotDePasseOublieBloc({
    required this.demanderReinitialisation,
    required this.verifierCode,
    required this.reinitialiserMotDePasse,
  }) : super(MotDePasseOublieInitial()) {
    on<EnvoyerCodeEvent>((e, emit) => _envoyer(e.identifiant.trim(), emit));
    on<RenvoyerCodeEvent>((_, emit) => _envoyer(state.identifiant, emit));
    on<VerifierCodeEvent>(_onVerifierCode);
    on<ReinitialiserMotDePasseEvent>(_onReinitialiserMotDePasse);
    on<RecommencerReinitialisation>(
      (_, emit) =>
          emit(MotDePasseOublieInitial(identifiant: state.identifiant)),
    );
  }

  Future<void> _envoyer(
    String identifiant,
    Emitter<MotDePasseOublieState> emit,
  ) async {
    final etape = state.etape;
    emit(MotDePasseOublieLoading(etape, identifiant: identifiant));
    final result = await demanderReinitialisation(identifiant);
    result.fold(
      (failure) =>
          emit(MotDePasseOublieError(etape, failure, identifiant: identifiant)),
      (_) =>
          emit(CodeEnvoye(identifiant: identifiant, envoyeLe: DateTime.now())),
    );
  }

  Future<void> _onVerifierCode(
    VerifierCodeEvent event,
    Emitter<MotDePasseOublieState> emit,
  ) async {
    final identifiant = state.identifiant;
    emit(
      MotDePasseOublieLoading(
        EtapeReinitialisation.code,
        identifiant: identifiant,
        code: event.code,
      ),
    );
    final result = await verifierCode(identifiant, event.code);
    result.fold(
      (failure) => emit(
        MotDePasseOublieError(
          EtapeReinitialisation.code,
          failure,
          identifiant: identifiant,
        ),
      ),
      (_) => emit(CodeVerifie(identifiant: identifiant, code: event.code)),
    );
  }

  Future<void> _onReinitialiserMotDePasse(
    ReinitialiserMotDePasseEvent event,
    Emitter<MotDePasseOublieState> emit,
  ) async {
    final identifiant = state.identifiant;
    final code = state.code;
    emit(
      MotDePasseOublieLoading(
        EtapeReinitialisation.motDePasse,
        identifiant: identifiant,
        code: code,
      ),
    );
    final result = await reinitialiserMotDePasse({
      'identifiant': identifiant,
      'code': code,
      'password': event.motDePasse,
      'password_confirmation': event.confirmation,
    });
    result.fold(
      // Code expiré ou épuisé entre-temps : retour à l'étape du code (comme
      // Yobante) ; une erreur de saisie du mot de passe reste sur l'étape 3.
      (failure) => emit(
        ['CODE_INVALIDE', 'CODE_EPUISE'].contains(failure.code)
            ? MotDePasseOublieError(
                EtapeReinitialisation.code,
                failure,
                identifiant: identifiant,
              )
            : MotDePasseOublieError(
                EtapeReinitialisation.motDePasse,
                failure,
                identifiant: identifiant,
                code: code,
              ),
      ),
      (_) => emit(MotDePasseReinitialise()),
    );
  }
}
