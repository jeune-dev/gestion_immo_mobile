abstract class AccountEvent {}

class LoadSessions extends AccountEvent {}

class RevoquerSessionEvent extends AccountEvent {
  final String id;
  RevoquerSessionEvent(this.id);
}

class RevoquerToutesSessionsEvent extends AccountEvent {}

/// Première étape de la double authentification : la clé TOTP.
class InitialiserMfaEvent extends AccountEvent {
  final String motDePasse;
  InitialiserMfaEvent(this.motDePasse);
}

class ActiverMfaEvent extends AccountEvent {
  final String code;
  ActiverMfaEvent(this.code);
}

class DesactiverMfaEvent extends AccountEvent {
  final String motDePasse;
  final String code;
  DesactiverMfaEvent({required this.motDePasse, required this.code});
}

class RegenererCodesSecoursEvent extends AccountEvent {
  final String motDePasse;
  final String code;
  RegenererCodesSecoursEvent({required this.motDePasse, required this.code});
}
