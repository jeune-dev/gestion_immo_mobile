import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';
import 'bail_detail.dart';
import 'formulaires.dart';
import 'locataire_detail.dart';

class AppartementDetail extends StatelessWidget {
  const AppartementDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final annee = DateTime.now().year;
    return Chargeur<List<dynamic>>(
      page: true,
      titre: 'Appartement',
      charger: () => Future.wait([
        api.get<Map<String, dynamic>>('/appartements/$id'),
        api.get<Map<String, dynamic>>('/appartements/$id/rentabilite', query: {'du': '$annee-01-01', 'au': '$annee-12-31'}),
      ]),
      builder: (context, data, recharger) {
        final a = Map<String, dynamic>.from((data[0] as Map)['apartment'] as Map);
        final r = (data[1] as Map)['rentabilite'] as Map;
        final bail = a['current_lease'] as Map?;
        final locataire = a['current_tenant'] as Map?;
        final occupe = a['status'] == 'occupe';
        return Scaffold(
          appBar: AppBar(
            title: Text('Appartement ${a['number']}'),
            actions: [
              MenuActions(actions: [
                ('Modifier', () async {
                  if (await FormulairesBiens.appartement(context, existant: a) != null) recharger();
                }, false),
                if (!occupe)
                  ('Changer le statut', () async {
                    final statut = await showModalBottomSheet<String>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          // « Occupé » ne s'obtient QUE par l'activation d'un bail (§ 8)
                          for (final o in refs.options('statut_appartement').where((o) => o.code != 'occupe'))
                            ListTile(title: Text(o.label), selected: o.code == a['status'], onTap: () => Navigator.pop(ctx, o.code)),
                        ]),
                      ),
                    );
                    if (statut == null || !context.mounted) return;
                    await executer(context, () => api.patch<dynamic>('/appartements/$id/statut', body: {'status': statut}), succes: 'Statut modifié');
                    recharger();
                  }, false),
                ('Supprimer', () async {
                  final ok = await confirmer(context,
                      titre: 'Supprimer l’appartement',
                      message: 'Un appartement qui a un historique (baux, paiements) ne peut pas être supprimé.',
                      action: 'Supprimer',
                      danger: true);
                  if (ok == null || !context.mounted) return;
                  final fait = await executer(context, () => api.delete<dynamic>('/appartements/$id').then((_) => true), succes: 'Appartement supprimé');
                  if (fait == true && context.mounted) Navigator.pop(context);
                }, true),
              ]),
            ],
          ),
          floatingActionButton: occupe
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    final b = await FormulairesBiens.bail(context, initial: {
                      'apartment_id': id,
                      'apartment_id__libelle': 'Appartement ${a['number']}',
                      'rent_amount': a['rent_amount'],
                      'charges_amount': a['charges_amount'],
                    });
                    if (b != null && context.mounted) {
                      await ouvrir(context, BailDetail(id: '${b['id']}'));
                      recharger();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un bail'),
                ),
          body: RefreshIndicator(
            onRefresh: recharger,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
              Section(children: [
                Row(children: [
                  Expanded(child: Text('${(a['building'] as Map?)?['name'] ?? ''}', style: Theme.of(context).textTheme.titleMedium)),
                  Statut(FamilleStatut.appartement, 'statut_appartement', a['status'] as String?),
                ]),
                const SizedBox(height: AppTheme.espaceSm),
                Ligne('Type', refs.libelle('type_appartement', a['type'] as String?)),
                Ligne('Étage', a['floor'] == null ? null : '${a['floor']}'),
                Ligne('Surface', a['surface'] == null ? null : '${a['surface']} m²'),
                Ligne('Pièces', a['rooms_count'] == null ? null : '${a['rooms_count']}'),
                Ligne('Meublé', a['is_furnished'] == true ? 'Oui' : 'Non'),
                Ligne('Loyer', montant(a['rent_amount'] as num?)),
                Ligne('Charges', montant(a['charges_amount'] as num?)),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Occupation', padding: false, children: [
                if (bail != null && locataire != null)
                  ListTile(
                    leading: CircleAvatar(child: Text(initiales(locataire))),
                    title: Text(nomComplet(locataire)),
                    subtitle: Text('${bail['reference']} · depuis le ${date(bail['start_date'] as String?)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ouvrir(context, BailDetail(id: '${bail['id']}')),
                  )
                else
                  const ListTile(title: Text('Aucun locataire actuellement')),
                for (final h in ((a['tenant_history'] as List?) ?? []).cast<Map>().where((h) => h['id'] != bail?['id']))
                  ListTile(
                    dense: true,
                    title: Text(nomComplet(h['tenant'] as Map?)),
                    subtitle: Text('${date(h['start_date'] as String?)} → ${date((h['ended_on'] ?? h['end_date']) as String?)}'),
                    trailing: Statut(FamilleStatut.bail, 'statut_bail', h['status'] as String?),
                    onTap: () => ouvrir(context, LocataireDetail(id: '${(h['tenant'] as Map)['id']}')),
                  ),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Rentabilité $annee', children: [
                Ligne('Loyers encaissés', montant(r['loyers_encaisses'] as num?)),
                Ligne('Charges récupérées', montant(r['charges_recuperees'] as num?)),
                Ligne('Dépenses', montant(r['depenses'] as num?)),
                const Divider(),
                Ligne('Résultat net', null,
                    widget: Montant(r['resultat_net'] as num?,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: entier(r['resultat_net']) < 0 ? context.palette.danger : context.palette.succes))),
                Ligne('Impayés', montant(r['impayes'] as num?)),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              _Historique(id: id),
              const SizedBox(height: AppTheme.espaceLg),
              SectionDocuments(type: 'apartment', id: id),
            ]),
          ),
        );
      },
    );
  }
}

/// Historique de l'appartement (§ 25) : baux, paiements, travaux, dépenses, incidents.
class _Historique extends StatelessWidget {
  const _Historique({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.get<Map<String, dynamic>>('/appartements/$id/historique', query: {'limit': 15}),
      builder: (context, s) {
        final items = ((s.data?['items'] as List?) ?? []).cast<Map>();
        return Section(titre: 'Historique', padding: false, children: [
          if (!s.hasData) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          if (s.hasData && items.isEmpty) const ListTile(title: Text('Aucun événement')),
          for (final e in items)
            ListTile(
              dense: true,
              title: Text('${e['libelle']}'),
              subtitle: Text(date(e['date'] as String?)),
              trailing: e['montant'] == null ? null : Montant(e['montant'] as num?),
            ),
        ]);
      },
    );
  }
}
