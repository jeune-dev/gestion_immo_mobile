import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';

/// Fil de discussion propriétaire ↔ locataire (§ 54.1).
class FilDiscussion extends Equatable {
  final String id;

  /// Interlocuteur vu par le propriétaire.
  final PersonneResume? locataire;

  /// Interlocuteur vu par le locataire.
  final String? proprietaireNom;

  /// Texte du dernier message (`null` pour une photo).
  final String? dernierMessage;
  final bool aUnDernierMessage;
  final int nonLus;
  final String? dernierMessageLe;

  const FilDiscussion({
    required this.id,
    this.locataire,
    this.proprietaireNom,
    this.dernierMessage,
    this.aUnDernierMessage = false,
    this.nonLus = 0,
    this.dernierMessageLe,
  });

  @override
  List<Object?> get props => [
        id,
        locataire,
        proprietaireNom,
        dernierMessage,
        aUnDernierMessage,
        nonLus,
        dernierMessageLe
      ];
}

class Message extends Equatable {
  final String id;
  final String? filId;

  /// `proprietaire` ou `locataire`.
  final String? roleExpediteur;
  final String? texte;
  final DocumentApp? document;
  final String? creeLe;

  const Message(
      {required this.id,
      this.filId,
      this.roleExpediteur,
      this.texte,
      this.document,
      this.creeLe});

  @override
  List<Object?> get props =>
      [id, filId, roleExpediteur, texte, document, creeLe];
}
