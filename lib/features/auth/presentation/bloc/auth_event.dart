abstract class AuthEvent {}

/// Lancement de l'application : restauration de la session enregistrée.
class AuthDemarree extends AuthEvent {}

class ConnexionDemandee extends AuthEvent {
  final String identifiant;
  final String motDePasse;
  ConnexionDemandee({required this.identifiant, required this.motDePasse});
}

/// Seconde étape de connexion : code de l'application ou code de secours.
class MfaSoumise extends AuthEvent {
  final String? code;
  final String? codeSecours;
  MfaSoumise({this.code, this.codeSecours});
}

class MfaAbandonnee extends AuthEvent {}

class InscriptionDemandee extends AuthEvent {
  final Map<String, dynamic> corps;
  InscriptionDemandee(this.corps);
}

/// Activation du compte locataire avec le code d'invitation (§ 5 option B).
class ActivationDemandee extends AuthEvent {
  final Map<String, dynamic> corps;
  ActivationDemandee(this.corps);
}

class MotDePasseChangeDemande extends AuthEvent {
  final String actuel;
  final String nouveau;
  MotDePasseChangeDemande({required this.actuel, required this.nouveau});
}

/// Relit `GET /compte` (profil modifié, abonnement renouvelé, MFA activée…).
class CompteRechargeDemande extends AuthEvent {}

class DeconnexionDemandee extends AuthEvent {}

/// Le client HTTP n'a pas pu renouveler la session (bus d'événements).
class SessionExpiree extends AuthEvent {}

/// Un écran d'authentification s'ouvre : l'erreur d'un autre écran ne s'y affiche pas.
class AuthErreurEffacee extends AuthEvent {}
