import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/activer_mfa.dart';
import '../../domain/usecases/desactiver_mfa.dart';
import '../../domain/usecases/get_sessions.dart';
import '../../domain/usecases/initialiser_mfa.dart';
import '../../domain/usecases/regenerer_codes_secours.dart';
import '../../domain/usecases/revoquer_session.dart';
import '../../domain/usecases/revoquer_toutes_sessions.dart';
import 'account_event.dart';
import 'account_state.dart';

/// Sécurité du compte : appareils connectés et double authentification.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetSessions getSessions;
  final RevoquerSession revoquerSession;
  final RevoquerToutesSessions revoquerToutesSessions;
  final InitialiserMfa initialiserMfa;
  final ActiverMfa activerMfa;
  final DesactiverMfa desactiverMfa;
  final RegenererCodesSecours regenererCodesSecours;

  AccountBloc({
    required this.getSessions,
    required this.revoquerSession,
    required this.revoquerToutesSessions,
    required this.initialiserMfa,
    required this.activerMfa,
    required this.desactiverMfa,
    required this.regenererCodesSecours,
  }) : super(AccountInitial()) {
    on<LoadSessions>((_, emit) => _chargerSessions(emit));
    on<RevoquerSessionEvent>(_onRevoquerSession);
    on<RevoquerToutesSessionsEvent>(_onRevoquerToutesSessions);
    on<InitialiserMfaEvent>(_onInitialiserMfa);
    on<ActiverMfaEvent>(_onActiverMfa);
    on<DesactiverMfaEvent>(_onDesactiverMfa);
    on<RegenererCodesSecoursEvent>(_onRegenererCodesSecours);
  }

  Future<void> _onRevoquerSession(
    RevoquerSessionEvent event,
    Emitter<AccountState> emit,
  ) async {
    final result = await revoquerSession(event.id);
    await result.fold(
      (failure) async => emit(AccountActionError(failure)),
      (_) async {
        emit(AccountSuccess(message: 'Appareil déconnecté'));
        await _chargerSessions(emit);
      },
    );
  }

  Future<void> _onRevoquerToutesSessions(
    RevoquerToutesSessionsEvent event,
    Emitter<AccountState> emit,
  ) async {
    final result = await revoquerToutesSessions();
    await result.fold(
      (failure) async => emit(AccountActionError(failure)),
      (_) async {
        emit(AccountSuccess(message: 'Autres appareils déconnectés'));
        await _chargerSessions(emit);
      },
    );
  }

  Future<void> _onInitialiserMfa(
    InitialiserMfaEvent event,
    Emitter<AccountState> emit,
  ) async {
    final result = await initialiserMfa(event.motDePasse);
    result.fold(
      (failure) => emit(AccountActionError(failure)),
      (secret) => emit(SecretMfaLoaded(secret)),
    );
  }

  Future<void> _onActiverMfa(
    ActiverMfaEvent event,
    Emitter<AccountState> emit,
  ) async {
    final result = await activerMfa(event.code);
    result.fold(
      (failure) => emit(AccountActionError(failure)),
      (codes) {
        emit(CodesSecoursLoaded(codes));
        emit(AccountSuccess(
          message: 'Double authentification activée',
          compteModifie: true,
        ));
      },
    );
  }

  Future<void> _onDesactiverMfa(
    DesactiverMfaEvent event,
    Emitter<AccountState> emit,
  ) async {
    final result = await desactiverMfa(
      motDePasse: event.motDePasse,
      code: event.code,
    );
    result.fold(
      (failure) => emit(AccountActionError(failure)),
      (_) => emit(AccountSuccess(
        message: 'Double authentification désactivée',
        compteModifie: true,
      )),
    );
  }

  Future<void> _onRegenererCodesSecours(
    RegenererCodesSecoursEvent event,
    Emitter<AccountState> emit,
  ) async {
    final result = await regenererCodesSecours(
      motDePasse: event.motDePasse,
      code: event.code,
    );
    result.fold(
      (failure) => emit(AccountActionError(failure)),
      (codes) => emit(CodesSecoursLoaded(codes)),
    );
  }

  /// Relit les appareils connectés. Si la liste est déjà affichée, un échec
  /// de relecture s'affiche comme un message.
  Future<void> _chargerSessions(Emitter<AccountState> emit) async {
    final dejaAffichee = state is! AccountInitial && state is! AccountError;
    final result = await getSessions();
    result.fold(
      (failure) => emit(
        dejaAffichee ? AccountActionError(failure) : AccountError(failure),
      ),
      (sessions) => emit(SessionsLoaded(sessions)),
    );
  }
}
