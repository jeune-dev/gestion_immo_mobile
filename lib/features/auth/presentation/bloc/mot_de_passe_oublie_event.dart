abstract class MotDePasseOublieEvent {}

/// Demande d'un code à 6 chiffres pour [identifiant] (téléphone ou e-mail).
class EnvoyerCodeEvent extends MotDePasseOublieEvent {
  final String identifiant;
  EnvoyerCodeEvent(this.identifiant);
}

class ReinitialiserMotDePasseEvent extends MotDePasseOublieEvent {
  final String identifiant;
  final String code;
  final String motDePasse;
  final String confirmation;

  ReinitialiserMotDePasseEvent({
    required this.identifiant,
    required this.code,
    required this.motDePasse,
    required this.confirmation,
  });
}

/// Retour à la saisie de l'identifiant (« Renvoyer un code »).
class RecommencerReinitialisation extends MotDePasseOublieEvent {}
