/// identifiant_validator.dart — Contrôle des saisies côté application.
///
/// Retour immédiat pendant la saisie : l'utilisateur voit tout de suite qu'il
/// manque un chiffre à son code, sans attendre un aller-retour réseau.
///
/// L'API reste l'autorité : ces règles reprennent les siennes. Deux exceptions
/// assumées, plus strictes qu'elle : la longueur d'un numéro sans indicatif et
/// les caractères d'un prénom ou d'un nom.
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

  // ── Téléphone ─────────────────────────────────────────────────────────────

  /// Numéro sénégalais à 9 chiffres, ou numéro international commençant par
  /// `+` ou `00` (8 à 15 chiffres, indicatif compris). Rendu au format de l'API
  /// (+221771234567), quelle que soit la façon de l'écrire.
  ///
  /// Plus strict que l'API sur un numéro sans indicatif : elle accepte aussi une
  /// longueur courte, qui ne correspondrait à aucun numéro réel.
  static ResultatValidation telephone(
    String? saisie, {
    bool obligatoire = false,
  }) {
    final brut = (saisie ?? '').trim();
    if (brut.isEmpty) {
      return obligatoire
          ? const ResultatValidation.invalide('Obligatoire')
          : const ResultatValidation.valide('');
    }
    if (!RegExp(r'^[+]?[\d\s().-]+$').hasMatch(brut)) {
      return const ResultatValidation.invalide('Numéro de téléphone invalide');
    }
    final international = brut.startsWith('+') || brut.startsWith('00');
    var chiffres = brut.replaceAll(RegExp(r'\D'), '');
    if (international) {
      if (chiffres.startsWith('00')) chiffres = chiffres.substring(2);
      if (chiffres.length < 8 || chiffres.length > 15) {
        return const ResultatValidation.invalide(
          'Numéro international invalide',
        );
      }
      return ResultatValidation.valide('+$chiffres');
    }
    chiffres = chiffres.replaceFirst(RegExp(r'^0+'), '');
    if (chiffres.startsWith('221') && chiffres.length == 12) {
      return ResultatValidation.valide('+$chiffres');
    }
    if (chiffres.length != 9) {
      return const ResultatValidation.invalide(
        'Le numéro doit contenir 9 chiffres',
      );
    }
    return ResultatValidation.valide('+221$chiffres');
  }

  /// Téléphone ou e-mail dans un seul champ (mot de passe oublié).
  static ResultatValidation identifiant(String? saisie) {
    final brut = (saisie ?? '').trim();
    if (brut.isEmpty) return const ResultatValidation.invalide('Obligatoire');
    if (brut.contains('@')) {
      final r = email(brut);
      return r.estBloquant
          ? r
          : ResultatValidation.valide(r.valeur!.toLowerCase());
    }
    return telephone(brut);
  }

  // ── Prénom et nom ─────────────────────────────────────────────────────────

  static final _nom = RegExp(r"^\p{L}[\p{L}\p{M}\s'’.\-]*$", unicode: true);

  /// Lettres, espaces, apostrophes, points et tirets ; 80 caractères au plus.
  static ResultatValidation nom(String? saisie, {bool obligatoire = true}) {
    final brut = (saisie ?? '').trim();
    if (brut.isEmpty) {
      return obligatoire
          ? const ResultatValidation.invalide('Obligatoire')
          : const ResultatValidation.valide('');
    }
    if (brut.length > 80) {
      return const ResultatValidation.invalide('80 caractères maximum');
    }
    if (!_nom.hasMatch(brut)) {
      return const ResultatValidation.invalide(
        'Lettres, espaces, apostrophes et tirets uniquement',
      );
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
    if (brut.length > 128) {
      return const ResultatValidation.invalide('128 caractères maximum');
    }
    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(brut)) {
      return const ResultatValidation.invalide(
        'Une majuscule, une minuscule et un chiffre',
      );
    }
    return ResultatValidation.valide(brut);
  }

  // ── Codes ─────────────────────────────────────────────────────────────────

  /// Code numérique de [longueur] chiffres : double authentification et
  /// réinitialisation (6), invitation d'un locataire (8).
  /// Code « mot de passe oublié » : 8 lettres ou chiffres ; casse et espaces
  /// indifférents (le code est rendu en majuscules, sans espaces).
  static ResultatValidation codeReinitialisation(String? saisie) {
    final brut = (saisie ?? '').replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(brut)) {
      return ResultatValidation.invalide('8 lettres ou chiffres');
    }
    return ResultatValidation.valide(brut);
  }

  static ResultatValidation code(String? saisie, {required int longueur}) {
    final brut = (saisie ?? '').trim();
    if (!RegExp('^\\d{$longueur}\$').hasMatch(brut)) {
      return ResultatValidation.invalide('$longueur chiffres');
    }
    return ResultatValidation.valide(brut);
  }
}
