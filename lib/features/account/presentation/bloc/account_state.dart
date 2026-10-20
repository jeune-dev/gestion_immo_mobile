import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/account/domain/entities/session_appareil.dart';

abstract class AccountState {}

class AccountInitial extends AccountState {}

class SessionsLoaded extends AccountState {
  final List<SessionAppareil> sessions;
  SessionsLoaded(this.sessions);
}

/// Clé TOTP en cours d'ajout dans l'application d'authentification.
class SecretMfaLoaded extends AccountState {
  final SecretMfa secret;
  SecretMfaLoaded(this.secret);
}

/// Codes de secours à afficher une seule fois.
class CodesSecoursLoaded extends AccountState {
  final List<String> codes;
  CodesSecoursLoaded(this.codes);
}

class AccountSuccess extends AccountState {
  final String message;

  /// Le compte a changé (double authentification) : la session globale doit
  /// le relire.
  final bool compteModifie;

  AccountSuccess(
      {this.message = 'Opération réussie', this.compteModifie = false});
}

/// Échec de la lecture des appareils connectés.
class AccountError extends AccountState {
  final Failure failure;
  AccountError(this.failure);

  String get message => failure.messageComplet;
}

/// Échec d'une action : un simple message, l'écran reste affiché.
class AccountActionError extends AccountState {
  final Failure failure;
  AccountActionError(this.failure);

  String get message => failure.messageComplet;
}
