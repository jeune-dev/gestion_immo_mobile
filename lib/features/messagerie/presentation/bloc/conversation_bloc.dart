import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../../domain/entities/messagerie.dart';
import '../../domain/usecases/envoyer_message.dart';
import '../../domain/usecases/envoyer_photo_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/marquer_fil_lu.dart';
import '../../domain/usecases/trouver_fil_locataire.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

/// Conversation (propriétaire ou locataire) : messages texte et photos.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetMessages getMessages;
  final MarquerFilLu marquerFilLu;
  final TrouverFilLocataire trouverFilLocataire;
  final EnvoyerMessage envoyerMessage;
  final EnvoyerPhotoMessage envoyerPhotoMessage;

  bool _espaceLocataire = false;
  String? _locataireId;
  String? _filId;

  ConversationBloc({
    required this.getMessages,
    required this.marquerFilLu,
    required this.trouverFilLocataire,
    required this.envoyerMessage,
    required this.envoyerPhotoMessage,
  }) : super(ConversationInitial()) {
    on<InitialiserConversation>(_onInitialiserConversation);
    on<RafraichirMessages>((_, emit) => _charger(emit));
    on<EnvoyerMessageEvent>(_onEnvoyerMessage);
    on<EnvoyerPhotoEvent>(_onEnvoyerPhoto);
  }

  Future<void> _onInitialiserConversation(
    InitialiserConversation event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    _espaceLocataire = event.espaceLocataire;
    _locataireId = event.locataireId;
    _filId = event.filId;
    // Ouvert depuis la fiche locataire : retrouver le fil existant, s'il y
    // en a un
    if (_filId == null && _locataireId != null) {
      final result = await trouverFilLocataire(_locataireId!);
      _filId = result.fold((_) => null, (filId) => filId);
    }
    await _charger(emit);
  }

  Future<void> _onEnvoyerMessage(
    EnvoyerMessageEvent event,
    Emitter<ConversationState> emit,
  ) =>
      _envoyer(
        emit,
        envoyerMessage(
          event.texte,
          filId: _filId,
          locataireId: _espaceLocataire ? null : _locataireId,
        ),
      );

  Future<void> _onEnvoyerPhoto(
    EnvoyerPhotoEvent event,
    Emitter<ConversationState> emit,
  ) =>
      _envoyer(
        emit,
        envoyerPhotoMessage(
          event.chemin,
          filId: _filId,
          locataireId: _espaceLocataire ? null : _locataireId,
        ),
      );

  Future<void> _envoyer(
    Emitter<ConversationState> emit,
    Future<Either<Failure, Message>> envoi,
  ) async {
    final actuel = state is ConversationLoaded
        ? state as ConversationLoaded
        : ConversationLoaded();
    emit(actuel.copyWith(envoi: true));
    final result = await envoi;
    await result.fold(
      (failure) async {
        emit(ConversationActionError(failure));
        emit(actuel.copyWith(envoi: false));
      },
      (message) async {
        _filId ??= message.filId;
        emit(MessageEnvoye());
        emit(actuel.copyWith(envoi: false));
        await _charger(emit);
      },
    );
  }

  Future<void> _charger(Emitter<ConversationState> emit) async {
    final filId = _filId;
    // Pas encore de conversation avec ce locataire : liste vide
    if (filId == null) return emit(ConversationLoaded());
    final result = await getMessages(filId, espaceLocataire: _espaceLocataire);
    result.fold(
      (failure) => emit(ConversationError(failure)),
      (messages) {
        emit(ConversationLoaded(messages: messages));
        marquerFilLu(filId, espaceLocataire: _espaceLocataire).ignore();
      },
    );
  }
}
