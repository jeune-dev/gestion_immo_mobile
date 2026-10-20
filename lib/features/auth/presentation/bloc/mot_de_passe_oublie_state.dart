import 'package:gestion_immo_mobile/core/errors/failure.dart';

enum EtapeReinitialisation { identifiant, code, terminee }

abstract class MotDePasseOublieState {
  /// Étape affichée : saisie de l'identifiant, puis du code.
  final EtapeReinitialisation etape;
  MotDePasseOublieState(this.etape);
}

class MotDePasseOublieInitial extends MotDePasseOublieState {
  MotDePasseOublieInitial() : super(EtapeReinitialisation.identifiant);
}

class MotDePasseOublieLoading extends MotDePasseOublieState {
  MotDePasseOublieLoading(super.etape);
}

class CodeEnvoye extends MotDePasseOublieState {
  CodeEnvoye() : super(EtapeReinitialisation.code);
}

class MotDePasseReinitialise extends MotDePasseOublieState {
  MotDePasseReinitialise() : super(EtapeReinitialisation.terminee);
}

class MotDePasseOublieError extends MotDePasseOublieState {
  final Failure failure;
  String get message => failure.messageComplet;
  MotDePasseOublieError(super.etape, this.failure);
}
