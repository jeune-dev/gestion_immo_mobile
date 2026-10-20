/// Issue de la première étape de connexion.
sealed class ResultatConnexion {
  const ResultatConnexion();
}

/// Session ouverte : les jetons sont enregistrés.
class SessionOuverte extends ResultatConnexion {
  const SessionOuverte();
}

/// Double authentification active : un code est attendu avec ce jeton (5 min).
class DoubleAuthentificationRequise extends ResultatConnexion {
  final String jeton;
  const DoubleAuthentificationRequise(this.jeton);
}
