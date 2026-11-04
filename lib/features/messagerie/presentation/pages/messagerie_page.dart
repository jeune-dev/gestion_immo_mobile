import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/messagerie/domain/entities/messagerie.dart';
import 'package:gestion_immo_mobile/features/messagerie/domain/usecases/get_fils_discussion.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/conversation_page.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Fils de discussion : avec ses locataires (propriétaire) ou avec son propriétaire (locataire) — § 54.1.
class MessageriePage extends StatefulWidget {
  final bool espaceLocataire;
  const MessageriePage({super.key, this.espaceLocataire = false});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  final _liste = GlobalKey<ListePagineeState<FilDiscussion>>();

  @override
  Widget build(BuildContext context) {
    final locataire = widget.espaceLocataire;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        leading: LogoBarre.siRacine(context),
        leadingWidth: LogoBarre.largeur,
        title: Text(locataire ? 'Messages' : 'Messagerie'),
      ),
      body: ListePaginee<FilDiscussion>(
        key: _liste,
        vide: locataire
            ? 'Aucune conversation'
            : 'Aucune conversation. Écrivez à un locataire depuis sa fiche.',
        iconeVide: Icons.chat_bubble_outline,
        charger: (page) =>
            sl<GetFilsDiscussion>()(page: page, espaceLocataire: locataire),
        element: (context, f) {
          final nom = locataire
              ? (f.proprietaireNom ?? 'Propriétaire')
              : (f.locataire?.nomComplet ?? '—');
          final apercu = !f.aUnDernierMessage
              ? (locataire ? 'Écrivez à votre propriétaire' : 'Aucun message')
              : (f.dernierMessage ?? 'Photo');
          return TuileConversation(
            nom: nom,
            apercu: apercu,
            heure: ilYa(f.dernierMessageLe),
            nonLus: f.nonLus,
            initiales: locataire ? null : f.locataire?.initiales,
            onTap: () async {
              await ouvrir(
                context,
                locataire
                    ? ConversationPage.locataire(filId: f.id, titre: nom)
                    : ConversationPage.proprietaire(
                        locataireId: f.locataire?.id ?? '',
                        titre: nom,
                        filId: f.id,
                      ),
              );
              _liste.currentState?.recharger();
            },
          );
        },
      ),
    );
  }
}

/// Ouvre un fil de discussion à partir de son identifiant (notification de
/// message). S'il n'est pas retrouvé, ouvre la liste des conversations.
Future<void> ouvrirFilDiscussion(
  BuildContext context,
  String filId, {
  required bool espaceLocataire,
}) async {
  FilDiscussion? fil;
  var page = 1;
  var suite = true;
  while (fil == null && suite) {
    final r = await sl<GetFilsDiscussion>()(
      page: page,
      espaceLocataire: espaceLocataire,
    );
    final resultat = r.fold((_) => null, (p) => p);
    fil = resultat?.items.where((f) => f.id == filId).firstOrNull;
    suite = resultat?.aSuite ?? false;
    page++;
  }
  if (!context.mounted) return;
  if (fil == null) {
    await ouvrir(context, MessageriePage(espaceLocataire: espaceLocataire));
  } else if (espaceLocataire) {
    await ouvrir(
      context,
      ConversationPage.locataire(
        filId: fil.id,
        titre: fil.proprietaireNom ?? 'Propriétaire',
      ),
    );
  } else {
    await ouvrir(
      context,
      ConversationPage.proprietaire(
        locataireId: fil.locataire?.id ?? '',
        titre: fil.locataire?.nomComplet ?? '—',
        filId: fil.id,
      ),
    );
  }
}

/// Conversation dans la liste : avatar, nom, dernier message, heure et non-lus.
class TuileConversation extends StatelessWidget {
  final String nom;
  final String apercu;
  final String heure;
  final int nonLus;
  final String? initiales;
  final VoidCallback onTap;
  const TuileConversation({
    super.key,
    required this.nom,
    required this.apercu,
    required this.heure,
    required this.nonLus,
    required this.initiales,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    final nonLu = nonLus > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.espaceMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: p.primaireTeinte,
              foregroundColor: cs.primary,
              child: initiales == null
                  ? const Icon(Icons.person_outline)
                  : Text(
                      initiales!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(width: AppTheme.espaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.texte,
                      fontSize: 15,
                      fontWeight: nonLu ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    apercu,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nonLu ? p.texte : p.texteSecondaire,
                      fontSize: 13,
                      fontWeight: nonLu ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.espaceSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  heure,
                  style: TextStyle(
                    color: nonLu ? cs.primary : p.texteDiscret,
                    fontSize: 12,
                  ),
                ),
                if (nonLu) ...[
                  const SizedBox(height: AppTheme.espaceXs),
                  Badge(
                    label: Text('$nonLus'),
                    backgroundColor: cs.primary,
                    textColor: cs.onPrimary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
