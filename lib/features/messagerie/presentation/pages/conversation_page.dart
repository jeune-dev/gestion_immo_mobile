import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/messagerie/domain/entities/messagerie.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/bloc/conversation_bloc.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/bloc/conversation_event.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/bloc/conversation_state.dart';

/// Conversation (propriétaire ou locataire) : messages texte et photos.
class ConversationPage extends StatelessWidget {
  final String titre;
  final String? filId;
  final String? locataireId;
  final bool espaceLocataire;

  const ConversationPage._(
      {required this.titre,
      this.filId,
      this.locataireId,
      required this.espaceLocataire});

  factory ConversationPage.proprietaire(
          {required String locataireId,
          required String titre,
          String? filId}) =>
      ConversationPage._(
          titre: titre,
          locataireId: locataireId,
          filId: filId,
          espaceLocataire: false);

  factory ConversationPage.locataire(
          {required String filId, required String titre}) =>
      ConversationPage._(titre: titre, filId: filId, espaceLocataire: true);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ConversationBloc>()
        ..add(InitialiserConversation(
          espaceLocataire: espaceLocataire,
          filId: filId,
          locataireId: locataireId,
        )),
      child: _Conversation(
          titre: titre, moi: espaceLocataire ? 'locataire' : 'proprietaire'),
    );
  }
}

class _Conversation extends StatefulWidget {
  final String titre;
  final String moi;
  const _Conversation({required this.titre, required this.moi});

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  final _texte = TextEditingController();

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConversationBloc>();
    return BlocConsumer<ConversationBloc, ConversationState>(
      listener: (context, state) {
        if (state is ConversationActionError) {
          afficherErreurApi(context, state.failure);
        } else if (state is MessageEnvoye) {
          _texte.clear();
        }
      },
      // Les états ponctuels (envoi refusé, message envoyé) ne redessinent pas
      // l'écran.
      buildWhen: (_, state) =>
          state is! ConversationActionError && state is! MessageEnvoye,
      builder: (context, state) => _buildConversation(context, bloc, state),
    );
  }

  Widget _buildConversation(
    BuildContext context,
    ConversationBloc bloc,
    ConversationState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    final chargement =
        state is ConversationInitial || state is ConversationLoading;
    final failure = state is ConversationError ? state.failure : null;
    final messages =
        state is ConversationLoaded ? state.messages : const <Message>[];
    final envoi = state is ConversationLoaded && state.envoi;
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: Column(
        children: [
          Expanded(
            child: chargement
                ? const Center(child: CircularProgressIndicator())
                : failure != null
                    ? VueErreur(failure,
                        onReessayer: () => bloc.add(RafraichirMessages()))
                    : messages.isEmpty
                        ? const Vide('Aucun message. Écrivez le premier.',
                            icone: Icons.chat_bubble_outline)
                        : RefreshIndicator(
                            onRefresh: () async =>
                                bloc.add(RafraichirMessages()),
                            child: ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, i) {
                                final m = messages[messages.length - 1 - i];
                                final moi = m.roleExpediteur == widget.moi;
                                final doc = m.document;
                                return Align(
                                  alignment: moi
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.78),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: moi
                                          ? cs.primary
                                          : context.palette.surfaceAlt,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.rayonCarte),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (doc != null)
                                          InkWell(
                                            onTap: () =>
                                                ouvrirDocument(context, doc),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.rayon),
                                              child: SizedBox(
                                                  width: 200,
                                                  height: 150,
                                                  child: ImageApi(doc.id)),
                                            ),
                                          ),
                                        if (m.texte?.isNotEmpty == true)
                                          Text(m.texte!,
                                              style: TextStyle(
                                                  color: moi
                                                      ? cs.onPrimary
                                                      : cs.onSurface)),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateHeure(m.creeLe),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: (moi
                                                      ? cs.onPrimary
                                                      : cs.onSurface)
                                                  .withValues(alpha: 0.7)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Envoyer une photo',
                    onPressed: envoi
                        ? null
                        : () async {
                            final photo = await choisirPhoto(context);
                            if (photo != null) {
                              bloc.add(EnvoyerPhotoEvent(photo.path));
                            }
                          },
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _texte,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 4000,
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          hintText: 'Votre message', isDense: true),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Envoyer',
                    onPressed: envoi
                        ? null
                        : () {
                            final texte = _texte.text.trim();
                            if (texte.isNotEmpty) {
                              bloc.add(EnvoyerMessageEvent(texte));
                            }
                          },
                    icon: Icon(Icons.send, color: cs.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
