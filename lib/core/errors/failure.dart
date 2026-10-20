import 'exceptions.dart';

/// Échec d'une opération, renvoyé par les dépôts dans un `Either` (reprise de Sign).
///
/// Porte le `error.code` stable de l'API : la présentation s'y branche
/// (402 abonnement, 409 transition…) ; [errorMessage] s'affiche tel quel.
/// Implémente [Exception] pour qu'un formulaire générique puisse la relancer.
abstract class Failure implements Exception {
  final String errorMessage;
  final String? code;
  final int? status;
  final List<String> details;
  final String? requestId;
  final int? retryAfter;

  /// 402 : abonnement échu ou suspendu, l'espace est en lecture seule.
  bool get abonnementRequis => status == 402 || code == 'ABONNEMENT_REQUIS';

  const Failure(
      {required this.errorMessage,
      this.code,
      this.status,
      this.details = const [],
      this.requestId,
      this.retryAfter});

  /// Message complet, avec les champs refusés quand l'API les détaille.
  String get messageComplet {
    if (code == 'DONNEES_INVALIDES' && details.isNotEmpty) {
      return '$errorMessage : ${details.join(' · ')}';
    }
    if (status != null && status! >= 500 && requestId != null) {
      return '$errorMessage (référence : $requestId)';
    }
    return errorMessage;
  }

  @override
  String toString() => messageComplet;

  @override
  int get hashCode => Object.hash(runtimeType, errorMessage, code);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          other.runtimeType == runtimeType &&
          other.errorMessage == errorMessage &&
          other.code == code;

  /// Traduit l'erreur normalisée du client HTTP.
  static Failure depuis(ApiException e) => e.estReseau
      ? ReseauFailure(errorMessage: e.message)
      : ServerFailure(
          errorMessage: e.message,
          code: e.code,
          status: e.status,
          details: e.details,
          requestId: e.requestId,
          retryAfter: e.retryAfter);
}

/// Réponse d'erreur de l'API (4xx, 5xx).
class ServerFailure extends Failure {
  const ServerFailure(
      {required super.errorMessage,
      super.code,
      super.status,
      super.details,
      super.requestId,
      super.retryAfter});
}

/// Aucune réponse du serveur (pas de réseau, délai dépassé).
class ReseauFailure extends Failure {
  const ReseauFailure({required super.errorMessage}) : super(code: 'RESEAU');
}

/// Donnée locale illisible (cache, file hors ligne).
class CacheFailure extends Failure {
  const CacheFailure({required super.errorMessage});
}
