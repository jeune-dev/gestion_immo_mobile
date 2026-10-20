/// identifiant_validator.dart — Contrôle des saisies côté application.
///
/// Retour immédiat pendant la saisie : l'utilisateur voit tout de suite qu'il
/// manque un chiffre à son code, sans attendre un aller-retour réseau.
///
/// L'API reste l'autorité : ces règles reprennent les siennes sans jamais les
/// durcir, pour ne pas bloquer une saisie que le serveur accepterait.
library;

/// Les deux issues d'un contrôle.
enum NiveauValidation { valide, invalide }

class ResultatValidation {
  final NiveauValidation niveau;

  /// Valeur normalisée, prête à être envoyée à l'API (null si invalide).
  final String? valeur;

  /// Message affichable tel quel sous le champ.
  final String message;

  const ResultatValidation._(this.niveau, this.valeur, this.message);

  const ResultatValidation.valide(String valeurNormalisee)
      : this._(NiveauValidation.valide, valeurNormalisee, 'Saisie valide');

  const ResultatValidation.invalide(String raison)
      : this._(NiveauValidation.invalide, null, raison);

  bool get estBloquant => niveau == NiveauValidation.invalide;
  bool get estAcceptable => niveau != NiveauValidation.invalide;

  /// Message à passer au `validator:` d'un TextFormField — null si acceptable.
  String? get erreurFormulaire => estBloquant ? message : null;
}

class IdentifiantValidator {
  IdentifiantValidator._();

  // ── E-mail ────────────────────────────────────────────────────────────────

  /// Contrôle syntaxique. L'e-mail étant souvent facultatif, une saisie vide
  /// n'est une erreur que si [obligatoire] est vrai.
  static ResultatValidation email(String? saisie, {bool obligatoire = false}) {
    final brut = (saisie ?? '').trim();
    if (brut.isEmpty) {
      return obligatoire
          ? const ResultatValidation.invalide('Obligatoire')
          : const ResultatValidation.valide('');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(brut)) {
      return const ResultatValidation.invalide('E-mail invalide');
    }
    return ResultatValidation.valide(brut);
  }

  // ── Mot de passe ──────────────────────────────────────────────────────────

  /// Règle de l'API : 8 caractères, une majuscule, une minuscule, un chiffre.
  static ResultatValidation motDePasse(String? saisie) {
    final brut = saisie ?? '';
    if (brut.length < 8) {
      return const ResultatValidation.invalide('8 caractères minimum');
    }
    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(brut)) {
      return const ResultatValidation.invalide(
          'Une majuscule, une minuscule et un chiffre');
    }
    return ResultatValidation.valide(brut);
  }

  // ── Codes ─────────────────────────────────────────────────────────────────

  /// Code numérique de [longueur] chiffres : double authentification et
  /// réinitialisation (6), invitation d'un locataire (8).
  static ResultatValidation code(String? saisie, {required int longueur}) {
    final brut = (saisie ?? '').trim();
    if (!RegExp('^\\d{$longueur}\$').hasMatch(brut)) {
      return ResultatValidation.invalide('$longueur chiffres');
    }
    return ResultatValidation.valide(brut);
  }
}
