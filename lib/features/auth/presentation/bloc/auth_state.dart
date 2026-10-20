import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../../domain/entities/compte.dart';

enum StatutSession { inconnu, deconnecte, connecte }

/// Session de l'utilisateur et espace à afficher (propriétaire ou locataire).
class AuthState extends Equatable {
  final StatutSession statut;
  final Compte? compte;

  /// Une demande (connexion, inscription…) est en cours d'envoi.
  final bool enCours;
  final Failure? failure;

  /// Double authentification attendue pour terminer la connexion.
  final String? mfaJeton;

  /// Message de réussite d'une action ponctuelle (changement de mot de passe).
  final String? succes;

  /// Change à chaque message ponctuel, pour qu'un même message se réaffiche.
  final int version;

  bool get connecte => statut == StatutSession.connecte;
  bool get doitChangerMotDePasse =>
      compte?.utilisateur.doitChangerMotDePasse ?? false;
  bool get lectureSeule => compte?.lectureSeule ?? false;

  const AuthState({
    this.statut = StatutSession.inconnu,
    this.compte,
    this.enCours = false,
    this.failure,
    this.mfaJeton,
    this.succes,
    this.version = 0,
  });

  AuthState copyWith({
    StatutSession? statut,
    Compte? compte,
    bool? enCours,
    Failure? failure,
    String? mfaJeton,
    String? succes,
    bool effacerFailure = false,
    bool effacerMfa = false,
    bool effacerSucces = false,
  }) =>
      AuthState(
        statut: statut ?? this.statut,
        compte: compte ?? this.compte,
        enCours: enCours ?? this.enCours,
        failure: effacerFailure ? null : failure ?? this.failure,
        mfaJeton: effacerMfa ? null : mfaJeton ?? this.mfaJeton,
        succes: effacerSucces ? null : succes ?? this.succes,
        version: failure != null || succes != null ? version + 1 : version,
      );

  @override
  List<Object?> get props =>
      [statut, compte, enCours, failure, mfaJeton, succes, version];
}
