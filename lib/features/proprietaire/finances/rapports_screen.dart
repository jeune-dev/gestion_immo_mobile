import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'periode.dart';

/// Rapports (§ 26) : financier, immobilier, travaux, locataires, rentabilité (§ 4.21).
class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> with SingleTickerProviderStateMixin {
  static const _types = [
    ('financier', 'Financier'),
    ('immobilier', 'Occupation'),
    ('rentabilite', 'Rentabilité'),
    ('locataires', 'Locataires'),
    ('travaux', 'Travaux'),
  ];
  late final _onglets = TabController(length: _types.length, vsync: this);
  Periode _periode = Periode.anneeCourante();

  Future<void> _exporter() async {
    final type = _types[_onglets.index].$1;
    try {
      afficherSucces(context, 'Préparation de l’export…');
      final octets = await api.telecharger('/rapports/$type', query: {'du': _periode.du, 'au': _periode.au, 'format': 'csv'});
      final f = File('${(await getTemporaryDirectory()).path}/rapport-$type-${_periode.du}-${_periode.au}.csv');
      await f.writeAsBytes(octets, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/csv')], subject: 'Rapport $type'));
    } catch (e) {
      if (mounted) afficherErreurApi(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        actions: [IconButton(tooltip: 'Exporter (CSV)', onPressed: _exporter, icon: const Icon(Icons.ios_share))],
        bottom: TabBar(
          controller: _onglets,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: [for (final t in _types) Tab(text: t.$2)],
        ),
      ),
      body: Column(children: [
        ChoixPeriode(periode: _periode, onChange: (p) => setState(() => _periode = p)),
        Expanded(
          child: TabBarView(controller: _onglets, children: [
            _Rapport(type: 'financier', periode: _periode, builder: _financier),
            _Rapport(type: 'immobilier', periode: _periode, builder: _immobilier),
            _Rentabilite(periode: _periode),
            _Rapport(type: 'locataires', periode: _periode, builder: _locataires),
            _Rapport(type: 'travaux', periode: _periode, builder: _travaux),
          ]),
        ),
      ]),
    );
  }

  static List<Widget> _financier(BuildContext context, Map r) {
    final rev = r['revenus'] as Map;
    final dep = r['depenses'] as Map;
    final imp = r['impayes'] as Map;
    final ch = r['charges'] as Map;
    return [
      Section(titre: 'Résultat', children: [
        Ligne('Loyers', montant(rev['loyers'] as num?)),
        Ligne('Charges récupérées', montant(rev['charges_recuperees'] as num?)),
        Ligne('Autres revenus', montant(rev['autres_revenus'] as num?)),
        Ligne('Total revenus', montant(rev['total'] as num?)),
        Ligne('Dépenses', montant(dep['total'] as num?)),
        const Divider(),
        Ligne('Bénéfice net', null,
            widget: Montant(r['benefice_net'] as num?,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 18, color: entier(r['benefice_net']) < 0 ? context.palette.danger : context.palette.succes))),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Impayés au ${date(imp['date'] as String?)}', children: [
        Ligne('Montant', montant(imp['montant'] as num?)),
        Ligne('Échéances', '${imp['echeances']}'),
        Ligne('Locataires', '${imp['locataires']}'),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Dépenses par catégorie', children: [
        for (final c in ((dep['par_categorie'] as List?) ?? []).cast<Map>()) Ligne('${c['name']}', montant(c['total'] as num?)),
        if (((dep['par_categorie'] as List?) ?? []).isEmpty) const Text('Aucune dépense'),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Charges', children: [
        Ligne('Factures communes', '${ch['nombre_factures']} · ${montant(ch['factures_total'] as num?)}'),
        Ligne('Refacturées', montant(ch['refacturees_locataires'] as num?)),
        Ligne('Récupérées', montant(ch['recuperees_locataires'] as num?)),
        Ligne('Reste à recouvrer', montant(ch['reste_a_recouvrer'] as num?)),
        Ligne('À la charge du propriétaire', montant(ch['a_charge_proprietaire'] as num?)),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Par immeuble', padding: false, children: [
        for (final b in ((r['par_immeuble'] as List?) ?? []).cast<Map>())
          ListTile(
            title: Text('${b['name']}'),
            subtitle: Text('Revenus ${montant((b['revenus'] as Map?)?['total'] as num?)} · dépenses ${montant(b['depenses'] as num?)} · impayés ${montant(b['impayes'] as num?)}'),
            trailing: Montant(b['benefice_net'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ]),
    ];
  }

  static List<Widget> _immobilier(BuildContext context, Map r) {
    final l = r['loyers'] as Map;
    return [
      Section(titre: 'Occupation', children: [
        Ligne('Immeubles', '${r['immeubles']}'),
        Ligne('Appartements', '${r['appartements']}'),
        Ligne('Occupés', '${r['occupes']}'),
        Ligne('Disponibles', '${r['disponibles']}'),
        Ligne('En travaux', '${r['en_travaux']}'),
        Ligne("Taux d'occupation", pourcent(r['taux_occupation'] as num?)),
        Ligne('Occupation sur la période', pourcent(r['taux_occupation_periode'] as num?)),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Loyers', children: [
        Ligne('Loyers mensuels (occupés)', montant(l['loyer_mensuel_occupes'] as num?)),
        Ligne('Loyer moyen', montant(l['loyer_moyen'] as num?)),
        Ligne('Loyer potentiel', montant(l['loyer_potentiel'] as num?)),
        Ligne('Manque à gagner (vacance)', montant(l['manque_a_gagner_vacance'] as num?)),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Par immeuble', padding: false, children: [
        for (final b in ((r['par_immeuble'] as List?) ?? []).cast<Map>())
          ListTile(
            title: Text('${b['name']}'),
            subtitle: Text('${b['occupes']} occupés sur ${b['appartements']} · ${b['city'] ?? ''}'),
            trailing: Text(pourcent(b['taux_occupation'] as num?), style: chiffresFixes),
          ),
      ]),
    ];
  }

  static List<Widget> _locataires(BuildContext context, Map r) {
    final arrivees = r['arrivees'] as Map;
    final departs = r['departs'] as Map;
    final imp = r['impayes'] as Map;
    return [
      Section(children: [
        Ligne('Locataires actifs', '${r['actifs']}'),
        Ligne('Arrivées', '${arrivees['nombre']}'),
        Ligne('Départs', '${departs['nombre']}'),
        Ligne('Impayés', montant(imp['total'] as num?)),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Locataires en impayé', padding: false, children: [
        for (final t in ((imp['locataires'] as List?) ?? []).cast<Map>())
          ListTile(
            title: Text(nomComplet(t)),
            subtitle: Text('${t['echeances']} échéance(s) · depuis le ${date(t['plus_ancienne_echeance'] as String?)}'),
            trailing: Montant(t['montant'] as num?),
          ),
        if (((imp['locataires'] as List?) ?? []).isEmpty) const ListTile(title: Text('Aucun impayé')),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Arrivées', padding: false, children: [
        for (final b in ((arrivees['baux'] as List?) ?? []).cast<Map>())
          ListTile(title: Text(nomComplet(b)), subtitle: Text('${b['building_name']} · ${b['apartment_number']} · ${date(b['date'] as String?)}')),
      ]),
      if (((departs['baux'] as List?) ?? []).isNotEmpty) ...[
        const SizedBox(height: AppTheme.espaceLg),
        Section(titre: 'Départs', padding: false, children: [
          for (final b in (departs['baux'] as List).cast<Map>())
            ListTile(title: Text(nomComplet(b)), subtitle: Text('${b['building_name']} · ${b['apartment_number']} · ${date(b['date'] as String?)}')),
        ]),
      ],
    ];
  }

  static List<Widget> _travaux(BuildContext context, Map r) {
    final couts = r['couts'] as Map;
    return [
      Section(children: [
        Ligne('Créés sur la période', '${r['crees_sur_periode']}'),
        Ligne('Terminés', '${r['termines']}'),
        Ligne('En cours', '${r['en_cours']}'),
        Ligne('En attente', '${r['en_attente']}'),
        Ligne('Annulés', '${r['annules']}'),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Coûts', children: [
        Ligne('Estimés', montant(couts['estime'] as num?)),
        Ligne('Réels', montant(couts['reel'] as num?)),
        Ligne('Dépenses liées', montant(couts['depenses_liees'] as num?)),
      ]),
      const SizedBox(height: AppTheme.espaceLg),
      Section(titre: 'Par catégorie', padding: false, children: [
        for (final c in ((r['par_categorie'] as List?) ?? []).cast<Map>())
          ListTile(
            title: Text(refs.libelle('categorie_travaux', c['category'] as String?)),
            subtitle: Text('${c['nombre']} chantier(s) · ${c['termines']} terminé(s)'),
            trailing: Montant(c['cout_reel'] as num?),
          ),
      ]),
    ];
  }
}

class _Rapport extends StatelessWidget {
  const _Rapport({required this.type, required this.periode, required this.builder});
  final String type;
  final Periode periode;
  final List<Widget> Function(BuildContext, Map) builder;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      cle: '${periode.du}|${periode.au}',
      charger: () => api.get<Map<String, dynamic>>('/rapports/$type', query: {'du': periode.du, 'au': periode.au}),
      builder: (context, data, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: builder(context, data['rapport'] as Map),
      ),
    );
  }
}

/// Rentabilité de chaque appartement, classée par résultat net (§ 48).
class _Rentabilite extends StatelessWidget {
  const _Rentabilite({required this.periode});
  final Periode periode;

  @override
  Widget build(BuildContext context) {
    return ListePaginee(
      cle: '${periode.du}|${periode.au}',
      vide: 'Aucun appartement',
      charger: (page) => api.get('/rapports/rentabilite', query: {'du': periode.du, 'au': periode.au, 'page': page, 'tri': '-resultat_net'}),
      element: (context, a) => ListTile(
        leading: CircleAvatar(child: Text('${a['rang']}')),
        title: Text('${a['building_name']} · ${a['apartment_number']}'),
        subtitle: Text('Revenus ${montant(a['revenus'] as num?)} · dépenses ${montant(a['depenses'] as num?)} · occupé ${pourcent(a['taux_occupation'] as num?)}'),
        trailing: Montant(a['resultat_net'] as num?,
            style: TextStyle(fontWeight: FontWeight.w600, color: entier(a['resultat_net']) < 0 ? context.palette.danger : context.palette.succes)),
      ),
    );
  }
}
