import 'exceptions.dart';
import 'failure.dart';

/// Messages adaptés à l'utilisateur pour les codes dont le texte de l'API
/// s'adresse à l'équipe de la plateforme.
const _messagesParCode = {
  'MODELE_NON_PUBLIE':
      'La génération de contrat n’est pas encore disponible pour ce type de bail. '
      'Le modèle doit d’abord être validé et publié par l’équipe Kërimmo.',
};

/// Message à afficher pour une erreur quelconque remontée à la présentation.
String messageErreur(Object e) => switch (e) {
  Failure f => _messagesParCode[f.code] ?? f.messageComplet,
  ApiException a => _messagesParCode[a.code] ?? a.messageComplet,
  _ => 'Une erreur est survenue.',
};

/// Vrai quand l'erreur vient d'une absence de réseau.
bool erreurReseau(Object e) =>
    (e is Failure && e.code == 'RESEAU') || (e is ApiException && e.estReseau);

/// Vrai pour un 402 : l'espace propriétaire est en lecture seule.
bool erreurAbonnement(Object e) =>
    (e is Failure && e.abonnementRequis) ||
    (e is ApiException && e.abonnementRequis);
