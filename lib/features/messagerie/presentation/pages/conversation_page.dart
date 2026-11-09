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
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/compteur_notifications.dart';

/// Conversation (propriétaire ou locataire) : messages texte et photos.
class ConversationPage extends StatelessWidget {
  final String titre;
  final String? filId;
  final String? locataireId;
  final bool espaceLocataire;

  const ConversationPage._({
    required this.titre,
    this.filId,
    this.locataireId,
    required this.espaceLocataire,
  });

  factory ConversationPage.proprietaire({
    required String locataireId,
    required String titre,
    String? filId,
  }) => ConversationPage._(
    titre: titre,
    locataireId: locataireId,
    filId: filId,
    espaceLocataire: false,
  );

  factory ConversationPage.locataire({
    required String filId,
    required String titre,
  }) => ConversationPage._(titre: titre, filId: filId, espaceLocataire: true);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final fil = filId;
        if (fil != null) CompteurNotifications.lireConversation(fil);
        return di.sl<ConversationBloc>()..add(
          InitialiserConversation(
            espaceLocataire: espaceLocataire,
            filId: filId,
            locataireId: locataireId,
          ),
        );
      },
      child: _Conversation(
        titre: titre,
        moi: espaceLocataire ? 'locataire' : 'proprietaire',
      ),
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
  static const _bordureSaisie = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(22)),
    borderSide: BorderSide.none,
  );

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
    final messages = state is ConversationLoaded
        ? state.messages
        : const <Message>[];
    final envoi = state is ConversationLoaded && state.envoi;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(widget.titre),
      ),
      body: Column(
        children: [
          Expanded(
            child: chargement
                ? const Center(child: CircularProgressIndicator())
                : failure != null
                ? VueErreur(
                    failure,
                    onReessayer: () => bloc.add(RafraichirMessages()),
                  )
                : messages.isEmpty
                ? const Vide(
                    'Aucun message pour le moment',
                    detail: 'Écrivez le premier message ci-dessous.',
                    icone: Icons.chat_bubble_outline,
                  )
                : RefreshIndicator(
                    onRefresh: () async => bloc.add(RafraichirMessages()),
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(AppTheme.espaceMd),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[messages.length - 1 - i];
                        final moi = m.roleExpediteur == widget.moi;
                        // Liste inversée : le message précédent est l'élément suivant.
                        final precedent = i + 1 < messages.length
                            ? messages[messages.length - 2 - i]
                            : null;
                        return Column(
                          children: [
                            if (nouveauJour(m.creeLe, precedent?.creeLe))
                              SeparateurJour(m.creeLe),
                            BulleMessage(message: m, moi: moi),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: context.palette.bordure)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _texte,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 4000,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Votre message',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.espaceLg,
                            vertical: 11,
                          ),
                          border: _bordureSaisie,
                          enabledBorder: _bordureSaisie,
                          focusedBorder: _bordureSaisie,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.espaceSm),
                    IconButton.filled(
                      tooltip: 'Envoyer',
                      style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: envoi
                          ? null
                          : () {
                              final texte = _texte.text.trim();
                              if (texte.isNotEmpty) {
                                bloc.add(EnvoyerMessageEvent(texte));
                              }
                            },
                      icon: const Icon(Icons.send, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deux dates tombent-elles sur des jours différents ? (`precedent` nul : oui)
bool nouveauJour(String? date, String? precedent) {
  final a = date == null ? null : DateTime.tryParse(date)?.toLocal();
  final b = precedent == null ? null : DateTime.tryParse(precedent)?.toLocal();
  if (a == null) return false;
  return b == null || a.year != b.year || a.month != b.month || a.day != b.day;
}

/// Repère de jour entre les messages.
class SeparateurJour extends StatelessWidget {
  final String? date_;
  const SeparateurJour(this.date_, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = date_ == null ? null : DateTime.tryParse(date_!)?.toLocal();
    final maintenant = DateTime.now();
    final aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final jour = d == null ? null : DateTime(d.year, d.month, d.day);
    final libelle = jour == aujourdhui
        ? 'Aujourd’hui'
        : jour == aujourdhui.subtract(const Duration(days: 1))
        ? 'Hier'
        : date(date_);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.espaceMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.espaceMd,
          vertical: AppTheme.espaceXs,
        ),
        decoration: BoxDecoration(
          color: context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          libelle,
          style: TextStyle(
            color: context.palette.texteSecondaire,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Bulle d'un message : à droite et en couleur pour ses propres messages.
class BulleMessage extends StatelessWidget {
  final Message message;
  final bool moi;
  const BulleMessage({super.key, required this.message, required this.moi});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doc = message.document;
    final texte = moi ? cs.onPrimary : context.palette.texte;
    const r = Radius.circular(AppTheme.rayonCarte);
    const pointe = Radius.circular(6);
    final heure = DateTime.tryParse(message.creeLe ?? '')?.toLocal();
    return Align(
      alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
        decoration: BoxDecoration(
          color: moi ? cs.primary : cs.surface,
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: moi ? r : pointe,
            bottomRight: moi ? pointe : r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doc != null) ...[
              InkWell(
                onTap: () => ouvrirDocument(context, doc),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.rayon),
                  child: SizedBox(
                    width: 220,
                    height: 160,
                    child: ImageApi(doc.id),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.espaceXs),
            ],
            if (message.texte?.isNotEmpty == true)
              Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  message.texte!,
                  style: TextStyle(color: texte, fontSize: 15, height: 1.3),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              heure == null
                  ? ''
                  : '${heure.hour.toString().padLeft(2, '0')}:${heure.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: texte.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
