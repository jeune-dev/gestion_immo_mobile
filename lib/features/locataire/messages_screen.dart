import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/navigation.dart';
import '../proprietaire/messagerie_screen.dart';

/// Messagerie avec le propriétaire (§ 54.1).
class MessagesLocataireScreen extends StatelessWidget {
  const MessagesLocataireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListePaginee(
        vide: 'Aucune conversation',
        iconeVide: Icons.chat_bubble_outline,
        charger: (page) => api.get('/locataire/messagerie', query: {'page': page}),
        element: (context, f) {
          final proprietaire = '${(f['owner'] as Map?)?['display_name'] ?? 'Propriétaire'}';
          final dernier = f['last_message'] as Map?;
          final nonLus = entier(f['unread_count']);
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(proprietaire, style: TextStyle(fontWeight: nonLus > 0 ? FontWeight.w600 : FontWeight.w400)),
            subtitle: Text(dernier == null ? 'Écrivez à votre propriétaire' : '${dernier['body'] ?? 'Photo'}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: nonLus > 0 ? Badge(label: Text('$nonLus')) : const Icon(Icons.chevron_right),
            onTap: () => ouvrir(context, ConversationScreen.locataire(filId: '${f['id']}', titre: proprietaire)),
          );
        },
      ),
    );
  }
}
