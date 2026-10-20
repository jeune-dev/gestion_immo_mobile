import 'package:equatable/equatable.dart';

/// Appareil connecté au compte (`GET /compte/sessions`).
class SessionAppareil extends Equatable {
  final String id;
  final String? nomAppareil;
  final String? plateforme;
  final String? derniereUtilisation;
  final bool courante;

  const SessionAppareil(
      {required this.id,
      this.nomAppareil,
      this.plateforme,
      this.derniereUtilisation,
      this.courante = false});

  @override
  List<Object?> get props =>
      [id, nomAppareil, plateforme, derniereUtilisation, courante];
}

/// Clé TOTP à ajouter dans l'application d'authentification.
class SecretMfa extends Equatable {
  final String secret;
  final String otpauthUrl;
  const SecretMfa({required this.secret, required this.otpauthUrl});

  @override
  List<Object?> get props => [secret, otpauthUrl];
}
