abstract class MotDePasseOublieEvent {}

/// Étape 1 : demande d'un code pour [identifiant] (téléphone ou e-mail).
class EnvoyerCodeEvent extends MotDePasseOublieEvent {
  final String identifiant;
  EnvoyerCodeEvent(this.identifiant);
}

/// Nouveau code pour le même identifiant (« Renvoyer le code »).
class RenvoyerCodeEvent extends MotDePasseOublieEvent {}

/// Étape 2 : vérification du code reçu, sans le consommer.
class VerifierCodeEvent extends MotDePasseOublieEvent {
  final String code;
  VerifierCodeEvent(this.code);
}

/// Étape 3 : nouveau mot de passe (avec le code vérifié).
class ReinitialiserMotDePasseEvent extends MotDePasseOublieEvent {
  final String motDePasse;
  final String confirmation;

  ReinitialiserMotDePasseEvent({
    required this.motDePasse,
    required this.confirmation,
  });
}

/// Retour à la saisie de l'identifiant (« Changer d'identifiant »).
class RecommencerReinitialisation extends MotDePasseOublieEvent {}
