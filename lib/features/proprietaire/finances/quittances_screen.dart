import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../theme/statuts.dart';

/// Quittances (§ 13) : consulter, télécharger, partager.
class QuittancesScreen extends StatelessWidget {
  const QuittancesScreen({super.key, this.chemin = '/quittances'});

  /// `/quittances` (propriétaire) ou `/locataire/quittances`.
  final String chemin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quittances')),
      body: ListePaginee(
        vide: 'Aucune quittance',
        iconeVide: Icons.description_outlined,
        charger: (page) => api.get(chemin, query: {'page': page, 'tri': '-issued_at'}),
        element: (context, q) => TuileQuittance(q: q, chemin: chemin),
      ),
    );
  }
}

class TuileQuittance extends StatelessWidget {
  const TuileQuittance({super.key, required this.q, this.chemin = '/quittances'});
  final Map q;
  final String chemin;

  @override
  Widget build(BuildContext context) {
    final echeance = q['schedule'] as Map?;
    final annulee = q['cancelled_at'] != null;
    final nom = 'quittance-${q['number']}.pdf';
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: Text('${q['number']} · ${echeance?['label'] ?? ''}'),
      subtitle: Text('${nomComplet(q['tenant'] as Map?)} · émise le ${date(q['issued_at'] as String?)}'),
      trailing: annulee
          ? const Pastille('Annulée', ton: TonStatut.neutre)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Montant(q['amount'] as num?),
              IconButton(
                tooltip: 'Partager',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => ouvrirPdf(context, '$chemin/${q['id']}/pdf', nom, partager: true),
              ),
            ]),
      onTap: () => ouvrirPdf(context, '$chemin/${q['id']}/pdf', nom),
    );
  }
}
