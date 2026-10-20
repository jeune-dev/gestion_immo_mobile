abstract class ConversationEvent {}

/// Ouverture de la conversation (propriétaire ou locataire).
class InitialiserConversation extends ConversationEvent {
  final bool espaceLocataire;

  /// Fil déjà connu ; sinon il est retrouvé depuis [locataireId].
  final String? filId;

  /// Côté propriétaire : le locataire à qui l'on écrit.
  final String? locataireId;

  InitialiserConversation({
    required this.espaceLocataire,
    this.filId,
    this.locataireId,
  });
}

/// Relecture des messages sans repasser par l'écran de chargement.
class RafraichirMessages extends ConversationEvent {}

class EnvoyerMessageEvent extends ConversationEvent {
  final String texte;
  EnvoyerMessageEvent(this.texte);
}

class EnvoyerPhotoEvent extends ConversationEvent {
  final String chemin;
  EnvoyerPhotoEvent(this.chemin);
}
