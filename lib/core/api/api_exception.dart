/// Erreur normalisée de l'API (contrat § 0 « Enveloppe des réponses »).
///
/// La logique de l'interface se branche sur [code] (stable) ; [message] est
/// rédigé pour l'utilisateur et s'affiche tel quel.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.status,
    this.code,
    this.details = const [],
    this.requestId,
    this.retryAfter,
  });

  final String message;
  final int? status;
  final String? code;
  final List<String> details;
  final String? requestId;

  /// Secondes indiquées par `Retry-After` (429, 503).
  final int? retryAfter;

  /// Aucune réponse du serveur (pas de réseau, délai dépassé).
  bool get estReseau => code == 'RESEAU';

  /// 402 : abonnement échu ou suspendu, l'espace est en lecture seule.
  bool get abonnementRequis => status == 402 || code == 'ABONNEMENT_REQUIS';

  /// Message complet, avec les champs refusés quand l'API les détaille.
  String get messageComplet {
    if (code == 'DONNEES_INVALIDES' && details.isNotEmpty) return '$message : ${details.join(' · ')}';
    if (status != null && status! >= 500 && requestId != null) return '$message (référence : $requestId)';
    return message;
  }

  @override
  String toString() => messageComplet;
}
