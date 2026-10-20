import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/documents/data/models/document_model.dart';
import '../../domain/entities/messagerie.dart';

class FilDiscussionModel extends FilDiscussion {
  const FilDiscussionModel({
    required super.id,
    super.locataire,
    super.proprietaireNom,
    super.dernierMessage,
    super.aUnDernierMessage,
    super.nonLus,
    super.dernierMessageLe,
  });

  factory FilDiscussionModel.fromJson(Map<String, dynamic> json) {
    final dernier = json['last_message'] as Map?;
    return FilDiscussionModel(
      id: '${json['id']}',
      locataire: PersonneResume.depuis(json['tenant']),
      proprietaireNom: (json['owner'] as Map?)?['display_name'] as String?,
      dernierMessage: dernier?['body'] as String?,
      aUnDernierMessage: dernier != null,
      nonLus: entier(json['unread_count']),
      dernierMessageLe: json['last_message_at'] as String?,
    );
  }
}

class MessageModel extends Message {
  const MessageModel(
      {required super.id,
      super.filId,
      super.roleExpediteur,
      super.texte,
      super.document,
      super.creeLe});

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: '${json['id']}',
        filId: json['thread_id']?.toString(),
        roleExpediteur: json['sender_role'] as String?,
        texte: json['body'] as String?,
        document: DocumentModel.depuis(json['document']),
        creeLe: json['created_at'] as String?,
      );
}
