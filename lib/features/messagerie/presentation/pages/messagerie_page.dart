import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/messagerie/domain/entities/messagerie.dart';
import 'package:gestion_immo_mobile/features/messagerie/domain/usecases/get_fils_discussion.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/conversation_page.dart';

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
      appBar: AppBar(title: Text(locataire ? 'Messages' : 'Messagerie')),
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
          return ListTile(
            leading: locataire
                ? const CircleAvatar(child: Icon(Icons.person_outline))
                : CircleAvatar(child: Text(f.locataire?.initiales ?? '?')),
            title: Text(nom,
                style: TextStyle(
                    fontWeight:
                        f.nonLus > 0 ? FontWeight.w600 : FontWeight.w400)),
            subtitle:
                Text(apercu, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: f.nonLus > 0
                ? Badge(label: Text('${f.nonLus}'))
                : locataire
                    ? const Icon(Icons.chevron_right)
                    : Text(ilYa(f.dernierMessageLe),
                        style: const TextStyle(fontSize: 12)),
            onTap: () async {
              await ouvrir(
                context,
                locataire
                    ? ConversationPage.locataire(filId: f.id, titre: nom)
                    : ConversationPage.proprietaire(
                        locataireId: f.locataire?.id ?? '',
                        titre: nom,
                        filId: f.id),
              );
              _liste.currentState?.recharger();
            },
          );
        },
      ),
    );
  }
}
