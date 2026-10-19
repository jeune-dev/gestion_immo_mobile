import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../core/widgets/sources.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';

/// Factures communes (§ 16) : eau, électricité, gardiennage… et leur répartition (§ 17).
class FacturesScreen extends StatefulWidget {
  const FacturesScreen({super.key, this.statut = ''});
  final String statut;

  @override
  State<FacturesScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends State<FacturesScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  late String _statut = widget.statut;

  /// Change à chaque retour d'une fiche : le bandeau « à répartir » se relit.
  int _version = 0;

  void _rafraichir() {
    _liste.currentState?.recharger();
    setState(() => _version++);
  }

  Future<void> _nouvelle() async {
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Nouvelle facture commune',
        initial: const {'recharge_to_tenants': true},
        intro: const Text('La méthode de répartition est obligatoire (§ 41). Vous pourrez prévisualiser la répartition avant de la valider.'),
        champs: champsFacture(),
        messageSucces: 'Facture enregistrée',
        envoyer: (c) async => (await api.post<Map<String, dynamic>>('/factures-communes', body: c, idempotence: cle))['invoice'],
      ),
    );
    if (r != null && mounted) {
      await ouvrir(context, FactureDetail(id: '${r['id']}'));
      _rafraichir();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factures communes')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _nouvelle, icon: const Icon(Icons.add), label: const Text('Facture')),
      body: Column(children: [
        _BandeauARepartir(cle: _version, onVoir: () => setState(() => _statut = 'brouillon')),
        Filtres(
          options: [('', 'Toutes'), for (final o in refs.options('statut_facture_commune')) (o.code, o.label)],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _statut,
            vide: 'Aucune facture commune',
            iconeVide: Icons.water_drop_outlined,
            charger: (page) => api.get('/factures-communes', query: {'page': page, 'status': _statut, 'tri': '-period_start'}),
            element: (context, f) => ListTile(
              title: Text('${refs.libelle('type_charge', f['charge_type'] as String?)} · ${(f['building'] as Map?)?['name'] ?? ''}'),
              subtitle: Text('${f['supplier'] ?? ''} · ${date(f['period_start'] as String?)} → ${date(f['period_end'] as String?)}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Montant(f['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
                Pastille(refs.libelle('statut_facture_commune', f['status'] as String?),
                    ton: f['status'] == 'repartie' ? TonStatut.succes : f['status'] == 'brouillon' ? TonStatut.avertissement : TonStatut.neutre),
              ]),
              onTap: () async {
                await ouvrir(context, FactureDetail(id: '${f['id']}'));
                _rafraichir();
              },
            ),
          ),
        ),
      ]),
    );
  }
}

/// Champs d'une facture commune, communs à la création et à la modification du brouillon.
List<Champ> champsFacture() => [
      Champ('building_id', 'Immeuble', type: TypeChamp.entite, obligatoire: true, entite: Sources.immeubles),
      const Champ('charge_type', 'Type de charge', type: TypeChamp.selection, referentiel: 'type_charge', obligatoire: true),
      const Champ('supplier', 'Fournisseur', maxLongueur: 120, indice: 'Ex. SENELEC, SEN’EAU'),
      const Champ('invoice_number', 'N° de facture', maxLongueur: 60),
      const Champ('amount', 'Montant total', type: TypeChamp.montant, obligatoire: true, min: 1),
      const Champ('period_start', 'Début de période', type: TypeChamp.date, obligatoire: true),
      const Champ('period_end', 'Fin de période', type: TypeChamp.date, obligatoire: true),
      const Champ('due_date', 'Date limite de paiement', type: TypeChamp.date, nullable: true),
      const Champ('allocation_method', 'Méthode de répartition', type: TypeChamp.selection, referentiel: 'methode_repartition', obligatoire: true),
      const Champ('recharge_to_tenants', 'Refacturer aux locataires', type: TypeChamp.interrupteur),
      const Champ('notes', 'Notes', type: TypeChamp.multiligne, maxLongueur: 5000),
    ];

/// Factures en brouillon à répartir (`GET /factures-communes/a-repartir`) : bandeau
/// au-dessus de la liste, qui filtre sur les brouillons d'un toucher.
class _BandeauARepartir extends StatelessWidget {
  const _BandeauARepartir({required this.cle, required this.onVoir});
  final Object cle;
  final VoidCallback onVoir;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(cle),
      future: api.get<Map<String, dynamic>>('/factures-communes/a-repartir'),
      builder: (context, s) {
        final n = entier(s.data?['count']);
        if (n == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Encadre(
            '$n facture${n > 1 ? 's' : ''} à répartir · ${montant(s.data?['total_amount'] as num?)}',
            ton: TonStatut.avertissement,
            action: TextButton(onPressed: onVoir, child: const Text('Voir')),
          ),
        );
      },
    );
  }
}

class FactureDetail extends StatelessWidget {
  const FactureDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Facture commune',
      charger: () => api.get<Map<String, dynamic>>('/factures-communes/$id'),
      builder: (context, data, recharger) {
        final f = data['invoice'] as Map;
        final lignes = ((f['allocations'] as List?) ?? []).cast<Map>();
        final brouillon = f['status'] == 'brouillon';
        return Scaffold(
          appBar: AppBar(
            title: Text(refs.libelle('type_charge', f['charge_type'] as String?)),
            actions: [
              if (f['status'] != 'annulee')
                MenuActions(actions: [
                  if (brouillon)
                    ('Modifier', () async {
                      final r = await EcranFormulaire.ouvrir<Map>(
                        context,
                        EcranFormulaire(
                          titre: 'Modifier la facture',
                          initial: {
                            ...Map<String, dynamic>.from(f),
                            if (f['building'] != null) 'building_id__libelle': (f['building'] as Map)['name'],
                          },
                          champs: champsFacture(),
                          messageSucces: 'Facture modifiée',
                          envoyer: (c) async => (await api.patch<Map<String, dynamic>>('/factures-communes/$id', body: c))['invoice'],
                        ),
                      );
                      if (r != null) recharger();
                    }, false),
                  ('Joindre la facture', () async {
                    final photo = await choisirPhoto(context);
                    if (photo == null || !context.mounted) return;
                    await executer(context, () => api.upload<dynamic>('/factures-communes/$id/document', cheminFichier: photo.path),
                        succes: 'Facture jointe');
                    recharger();
                  }, false),
                  ('Annuler la facture', () async {
                    final motif = await confirmer(context,
                        titre: 'Annuler la facture', message: 'Les charges refacturées non payées seront annulées.', motif: true, danger: true);
                    if (motif == null || !context.mounted) return;
                    await executer(context, () => api.post<dynamic>('/factures-communes/$id/annuler', body: {'reason': motif}),
                        succes: 'Facture annulée');
                    recharger();
                  }, true),
                ]),
            ],
          ),
          floatingActionButton: brouillon
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    if (await ouvrir<bool>(context, RepartitionScreen(facture: f)) == true) recharger();
                  },
                  icon: const Icon(Icons.call_split),
                  label: const Text('Répartir'),
                )
              : null,
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
            Section(children: [
              Ligne('Immeuble', '${(f['building'] as Map?)?['name'] ?? ''}'),
              Ligne('Fournisseur', f['supplier'] as String?),
              Ligne('N° de facture', f['invoice_number'] as String?),
              Ligne('Période', '${date(f['period_start'] as String?)} → ${date(f['period_end'] as String?)}'),
              Ligne('Montant', montant(f['amount'] as num?)),
              Ligne('Échéance', date(f['due_date'] as String?)),
              Ligne('Méthode', refs.libelle('methode_repartition', f['allocation_method'] as String?)),
              Ligne('Refacturée aux locataires', f['recharge_to_tenants'] == true ? 'Oui' : 'Non'),
              Ligne('Statut', refs.libelle('statut_facture_commune', f['status'] as String?)),
            ]),
            if (lignes.isNotEmpty) ...[
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Répartition', padding: false, children: [
                for (final l in lignes)
                  ListTile(
                    title: Text('Appartement ${(l['apartment'] as Map?)?['number'] ?? l['apartment_number'] ?? ''}'),
                    subtitle: Text('${l['explanation'] ?? ''}'),
                    trailing: Montant(l['amount'] as num?),
                  ),
              ]),
            ],
            const SizedBox(height: AppTheme.espaceLg),
            SectionDocuments(type: 'charge_invoice', ajout: false, id: id, titre: 'Pièces jointes'),
          ]),
        );
      },
    );
  }
}

/// Répartition (§ 17) : choix des appartements et, selon la méthode, consommation
/// ou montant de chacun ; aperçu calculé par l'API avant validation.
class RepartitionScreen extends StatefulWidget {
  const RepartitionScreen({super.key, required this.facture});
  final Map facture;

  @override
  State<RepartitionScreen> createState() => _RepartitionScreenState();
}

class _RepartitionScreenState extends State<RepartitionScreen> {
  List<Map>? _apparts;
  final Set<String> _choisis = {};
  final Map<String, TextEditingController> _valeurs = {};
  final _unite = TextEditingController(text: 'kWh');
  Map? _apercu;
  bool _envoi = false;

  String get _methode => '${widget.facture['allocation_method']}';
  bool get _parLigne => _methode == 'consommation' || _methode == 'personnalise';

  @override
  void initState() {
    super.initState();
    api.get<Map<String, dynamic>>('/appartements', query: {'building_id': widget.facture['building_id'], 'limit': 100, 'tri': 'number'}).then((r) {
      final items = (r['items'] as List).cast<Map>();
      setState(() {
        _apparts = items;
        _choisis.addAll(items.where((a) => a['status'] == 'occupe').map((a) => '${a['id']}'));
        for (final a in items) {
          _valeurs['${a['id']}'] = TextEditingController();
        }
      });
    }, onError: (Object e) {
      if (mounted) afficherErreurApi(context, e);
    });
  }

  Map<String, dynamic> _corps() {
    final ids = _choisis.toList();
    if (!_parLigne) return {'apartment_ids': ids};
    return {
      'lines': [
        for (final id in ids)
          {
            'apartment_id': id,
            if (_methode == 'consommation') 'consumption': num.tryParse(_valeurs[id]!.text.replaceAll(',', '.')) ?? 0,
            if (_methode == 'personnalise') 'amount': lireMontant(_valeurs[id]!.text) ?? 0,
          },
      ],
      // L'API refuse une unité vide ou de plus de 10 caractères
      if (_methode == 'consommation' && _unite.text.trim().isNotEmpty) 'unit': _unite.text.trim(),
    };
  }

  Future<void> _previsualiser() async {
    if (_choisis.isEmpty) return afficherErreur(context, 'Choisissez au moins un appartement');
    setState(() => _envoi = true);
    try {
      final r = await api.post<Map<String, dynamic>>('/factures-communes/${widget.facture['id']}/apercu', body: _corps());
      setState(() => _apercu = r['allocation'] as Map);
    } catch (e) {
      if (mounted) afficherErreurApi(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _valider() async {
    setState(() => _envoi = true);
    final r = await executer(context, () => api.post<dynamic>('/factures-communes/${widget.facture['id']}/repartir', body: _corps()),
        succes: 'Facture répartie');
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final a = _apercu;
    return Scaffold(
      appBar: AppBar(title: const Text('Répartir la facture')),
      body: _apparts == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Encadre('${refs.libelle('methode_repartition', _methode)} · total ${montant(widget.facture['amount'] as num?)}'),
              const SizedBox(height: AppTheme.espaceLg),
              if (_methode == 'consommation')
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
                  child: TextField(controller: _unite, maxLength: 10, decoration: const InputDecoration(labelText: 'Unité (kWh, m³…)')),
                ),
              Card(
                child: Column(children: [
                  for (final ap in _apparts!)
                    CheckboxListTile(
                      value: _choisis.contains('${ap['id']}'),
                      onChanged: (v) => setState(() {
                        _apercu = null;
                        v == true ? _choisis.add('${ap['id']}') : _choisis.remove('${ap['id']}');
                      }),
                      title: Text('Appartement ${ap['number']}'),
                      subtitle: _parLigne && _choisis.contains('${ap['id']}')
                          ? TextField(
                              controller: _valeurs['${ap['id']}'],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: _methode == 'consommation' ? 'Consommation (${_unite.text})' : 'Montant (FCFA)',
                              ),
                              onChanged: (_) => setState(() => _apercu = null),
                            )
                          : Text('${refs.libelle('statut_appartement', ap['status'] as String?)} · coefficient ${ap['charge_coefficient'] ?? 1}'),
                    ),
                ]),
              ),
              const SizedBox(height: AppTheme.espaceLg),
              if (a == null)
                FilledButton(onPressed: _envoi ? null : _previsualiser, child: const Text('Prévisualiser'))
              else ...[
                Section(titre: 'Aperçu', padding: false, children: [
                  for (final l in (a['lines'] as List).cast<Map>())
                    ListTile(
                      title: Text('Appartement ${l['apartment_number']}${l['tenant'] != null ? ' · ${nomComplet(l['tenant'] as Map)}' : ''}'),
                      subtitle: Text('${l['explanation']}'),
                      trailing: Montant(l['amount'] as num?),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Ligne('Refacturé aux locataires', montant(a['recharged_total'] as num?)),
                      Ligne('À la charge du propriétaire', montant(a['owner_share'] as num?)),
                    ]),
                  ),
                ]),
                const SizedBox(height: AppTheme.espaceLg),
                FilledButton(onPressed: _envoi ? null : _valider, child: const Text('Valider la répartition')),
                TextButton(onPressed: () => setState(() => _apercu = null), child: const Text('Modifier')),
              ],
            ]),
    );
  }
}

/// Charges refacturées aux locataires (§ 15).
class ChargesScreen extends StatefulWidget {
  const ChargesScreen({super.key});

  @override
  State<ChargesScreen> createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  String _statut = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charges refacturées')),
      body: Column(children: [
        Filtres(
          options: [('', 'Toutes'), for (final o in refs.options('statut_charge')) (o.code, o.label)],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee(
            cle: _statut,
            vide: 'Aucune charge refacturée',
            charger: (page) => api.get('/charges', query: {'page': page, 'status': _statut, 'tri': '-due_date'}),
            element: (context, c) => ListTile(
              title: Text('${nomComplet(c['tenant'] as Map?)} · ${(c['apartment'] as Map?)?['number'] ?? ''}'),
              subtitle: Text('${c['label']} · échéance ${date(c['due_date'] as String?)}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Montant(c['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
                Statut(FamilleStatut.charge, 'statut_charge', c['status'] as String?),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
