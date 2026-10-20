import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/messagerie/domain/entities/messagerie.dart';

abstract class ConversationState {}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<Message> messages;

  /// Un message ou une photo est en cours d'envoi.
  final bool envoi;

  ConversationLoaded({this.messages = const [], this.envoi = false});

  ConversationLoaded copyWith({List<Message>? messages, bool? envoi}) =>
      ConversationLoaded(
        messages: messages ?? this.messages,
        envoi: envoi ?? false,
      );
}

/// Lecture impossible : affichée à la place des messages.
class ConversationError extends ConversationState {
  final Failure failure;
  String get message => failure.messageComplet;
  ConversationError(this.failure);
}

/// Envoi refusé : affiché en message ponctuel.
class ConversationActionError extends ConversationState {
  final Failure failure;
  String get message => failure.messageComplet;
  ConversationActionError(this.failure);
}

/// Message envoyé : le champ de saisie se vide.
class MessageEnvoye extends ConversationState {}
