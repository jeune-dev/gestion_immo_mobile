import 'exceptions.dart';
import 'failure.dart';

/// Message à afficher pour une erreur quelconque remontée à la présentation.
String messageErreur(Object e) => switch (e) {
      Failure f => f.messageComplet,
      ApiException a => a.messageComplet,
      _ => 'Une erreur est survenue.',
    };

/// Vrai quand l'erreur vient d'une absence de réseau.
bool erreurReseau(Object e) =>
    (e is Failure && e.code == 'RESEAU') || (e is ApiException && e.estReseau);

/// Vrai pour un 402 : l'espace propriétaire est en lecture seule.
bool erreurAbonnement(Object e) =>
    (e is Failure && e.abonnementRequis) ||
    (e is ApiException && e.abonnementRequis);
