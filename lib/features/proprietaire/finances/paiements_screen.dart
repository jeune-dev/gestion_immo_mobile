import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/statuts.dart';
import 'quittances_screen.dart';

/// Paiements de loyer reçus (§ 12), avec remboursement.
class PaiementsScreen extends StatefulWidget {
  const PaiementsScreen({super.key});

  @override
  State<PaiementsScreen> createState() => _PaiementsScreenState();
}

class _PaiementsScreenState extends State<PaiementsScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  String _methode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements reçus')),
      body: Column(children: [
        Filtres(
          options: [('', 'Tous'), for (final o in refs.options('mode_paiement')) (o.code, o.label)],
          valeur: _methode,
          onChange: (v) => setState(() => _methode = v),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _methode,
            vide: 'Aucun paiement',
            charger: (page) => api.get('/paiements', query: {'page': page, 'method': _methode, 'tri': '-paid_on'}),
            element: (context, p) => ListTile(
              title: Text('${nomComplet(p['tenant'] as Map?)} · ${(p['apartment'] as Map?)?['number'] ?? ''}'),
              subtitle: Text('${date(p['paid_on'] as String?)} · ${refs.libelle('mode_paiement', p['method'] as String?)} · ${p['reference'] ?? ''}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Montant(p['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
                Statut(FamilleStatut.paiement, 'statut_paiement', p['status'] as String?),
              ]),
              onTap: () async {
                await ouvrir(context, PaiementDetail(id: '${p['id']}'));
                _liste.currentState?.recharger();
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class PaiementDetail extends StatelessWidget {
  const PaiementDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<List<dynamic>>(
      page: true,
      titre: 'Paiement',
      charger: () => Future.wait([
        api.get<Map<String, dynamic>>('/paiements/$id'),
        api.get<Map<String, dynamic>>('/paiements/$id/quittances'),
      ]),
      builder: (context, data, recharger) {
        final p = (data[0] as Map)['payment'] as Map;
        final quittances = ((data[1] as Map)['receipts'] as List).cast<Map>();
        final allocations = ((p['allocations'] as List?) ?? []).cast<Map>();
        return Scaffold(
          appBar: AppBar(
            title: Text('${p['reference']}'),
            actions: [
              if (p['status'] == 'valide')
                MenuActions(actions: [
                  ('Rembourser', () async {
                    final cle = nouvelleCle();
                    final r = await EcranFormulaire.ouvrir<Map>(
                      context,
                      EcranFormulaire(
                        titre: 'Rembourser le paiement',
                        intro: const Text('Les échéances concernées sont rouvertes et les quittances annulées.'),
                        champs: const [
                          Champ('reason', 'Motif', type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 500),
                          Champ('method', 'Moyen du remboursement', type: TypeChamp.selection, referentiel: 'mode_paiement'),
                        ],
                        libelleEnvoi: 'Rembourser',
                        messageSucces: 'Paiement remboursé',
                        envoyer: (c) => api.post<Map<String, dynamic>>('/paiements/$id/rembourser', body: c, idempotence: cle),
                      ),
                    );
                    if (r != null) recharger();
                  }, true),
                ]),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Ligne('Montant', null, widget: Montant(p['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18))),
              Ligne('Statut', null, widget: Statut(FamilleStatut.paiement, 'statut_paiement', p['status'] as String?)),
              Ligne('Locataire', nomComplet(p['tenant'] as Map?)),
              Ligne('Moyen', refs.libelle('mode_paiement', p['method'] as String?)),
              Ligne('Payé le', date(p['paid_on'] as String?)),
              Ligne('Référence', '${p['reference'] ?? ''}'),
              if (p['comment'] != null) Ligne('Commentaire', '${p['comment']}'),
              if (p['refunded_at'] != null) ...[
                Ligne('Remboursé le', dateHeure(p['refunded_at'] as String?)),
                Ligne('Motif', '${p['refund_reason'] ?? ''}'),
              ],
            ]),
            if (allocations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Section(titre: 'Imputation', children: [
                for (final a in allocations)
                  Ligne('${(a['schedule'] as Map?)?['label'] ?? (a['charge'] as Map?)?['label'] ?? 'Échéance'}', montant(a['amount'] as num?)),
              ]),
            ],
            const SizedBox(height: 16),
            Section(titre: 'Quittances', padding: false, children: [
              if (quittances.isEmpty) const ListTile(title: Text('Aucune quittance (échéance pas encore soldée)')),
              for (final q in quittances) TuileQuittance(q: q),
            ]),
          ]),
        );
      },
    );
  }
}
