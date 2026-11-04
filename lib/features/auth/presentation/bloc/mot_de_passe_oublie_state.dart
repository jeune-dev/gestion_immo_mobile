import 'package:gestion_immo_mobile/core/errors/failure.dart';

/// Les trois étapes (comme Yobante) : identifiant → code → nouveau mot de passe.
enum EtapeReinitialisation { identifiant, code, motDePasse, terminee }

abstract class MotDePasseOublieState {
  final EtapeReinitialisation etape;

  /// Identifiant et code retenus d'une étape à l'autre.
  final String identifiant;
  final String code;

  MotDePasseOublieState(this.etape, {this.identifiant = '', this.code = ''});
}

class MotDePasseOublieInitial extends MotDePasseOublieState {
  MotDePasseOublieInitial({super.identifiant})
    : super(EtapeReinitialisation.identifiant);
}

class MotDePasseOublieLoading extends MotDePasseOublieState {
  MotDePasseOublieLoading(super.etape, {super.identifiant, super.code});
}

/// Code envoyé (ou renvoyé) : [envoyeLe] fait démarrer le délai avant renvoi.
class CodeEnvoye extends MotDePasseOublieState {
  final DateTime envoyeLe;
  CodeEnvoye({required super.identifiant, required this.envoyeLe})
    : super(EtapeReinitialisation.code);
}

class CodeVerifie extends MotDePasseOublieState {
  CodeVerifie({required super.identifiant, required super.code})
    : super(EtapeReinitialisation.motDePasse);
}

class MotDePasseReinitialise extends MotDePasseOublieState {
  MotDePasseReinitialise() : super(EtapeReinitialisation.terminee);
}

class MotDePasseOublieError extends MotDePasseOublieState {
  final Failure failure;
  String get message => failure.messageComplet;
  MotDePasseOublieError(
    super.etape,
    this.failure, {
    super.identifiant,
    super.code,
  });
}
