import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/sources.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'periode.dart';

/// Caisse (§ 21) : entrées, sorties et solde de la période. Les cautions sont
/// exclues des revenus (§ 55) et présentées à part.
class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  Periode _periode = Periode.moisCourant();
  final _liste = GlobalKey<ListePagineeState>();
  int _version = 0;

  Future<void> _autreRevenu() async {
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Autre revenu',
        initial: {'occurred_on': aujourdhui(), 'method': 'especes'},
        champs: [
          const Champ('label', 'Libellé', obligatoire: true, maxLongueur: 200, indice: 'Ex. location de la terrasse'),
          const Champ('amount', 'Montant', type: TypeChamp.montant, obligatoire: true, min: 1),
          const Champ('method', 'Moyen', type: TypeChamp.selection, referentiel: 'mode_paiement', obligatoire: true),
          const Champ('occurred_on', 'Date', type: TypeChamp.date, obligatoire: true),
          Champ('building_id', 'Immeuble (facultatif)', type: TypeChamp.entite, entite: Sources.immeubles),
        ],
        messageSucces: 'Revenu enregistré',
        envoyer: (c) => api.post<Map<String, dynamic>>('/caisse/autres-revenus', body: c, idempotence: cle),
      ),
    );
    if (r != null) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Caisse')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _autreRevenu, icon: const Icon(Icons.add), label: const Text('Autre revenu')),
      body: Column(children: [
        ChoixPeriode(periode: _periode, onChange: (v) => setState(() => _periode = v)),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: '${_periode.du}|${_periode.au}|$_version',
            vide: 'Aucun mouvement sur la période',
            entete: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FutureBuilder<Map<String, dynamic>>(
                key: ValueKey('${_periode.du}|$_version'),
                future: api.get<Map<String, dynamic>>('/caisse/synthese', query: {'du': _periode.du, 'au': _periode.au}),
                builder: (context, s) {
                  if (!s.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                  final c = s.data!['caisse'] as Map;
                  final cautions = c['cautions'] as Map? ?? {};
                  return Column(children: [
                    Row(children: [
                      Expanded(child: ChiffreCle(libelle: 'Entrées', valeur: montant(c['entrees'] as num?), icone: Icons.south_west)),
                      const SizedBox(width: 8),
                      Expanded(child: ChiffreCle(libelle: 'Sorties', valeur: montant(c['sorties'] as num?), icone: Icons.north_east)),
                    ]),
                    const SizedBox(height: 8),
                    Section(children: [
                      Ligne('Solde de la période', null,
                          widget: Montant(c['solde'] as num?,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: entier(c['solde']) < 0 ? p.danger : p.succes))),
                      for (final d in ((c['detail_entrees'] as List?) ?? []).cast<Map>())
                        Ligne('+ ${refs.libelle('categorie_caisse', d['category'] as String?)}', montant(d['total'] as num?)),
                      for (final d in ((c['detail_sorties'] as List?) ?? []).cast<Map>())
                        Ligne('− ${refs.libelle('categorie_caisse', d['category'] as String?)}', montant(d['total'] as num?)),
                      const Divider(),
                      Ligne('Cautions détenues (hors revenus)', montant(cautions['solde'] as num?)),
                    ]),
                    const SizedBox(height: AppTheme.espaceSm),
                  ]);
                },
              ),
            ),
            charger: (page) => api.get('/caisse', query: {'page': page, 'du': _periode.du, 'au': _periode.au}),
            element: (context, m) {
              final entree = m['direction'] == 'entree';
              final annule = m['cancelled_at'] != null;
              return ListTile(
                leading: Icon(entree ? Icons.south_west : Icons.north_east, color: entree ? p.succes : p.texteSecondaire),
                title: Text('${m['label']}', style: annule ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                subtitle: Text('${date(m['occurred_on'] as String?)} · ${refs.libelle('categorie_caisse', m['category'] as String?)} · '
                    '${refs.libelle('mode_paiement', m['method'] as String?)}${annule ? ' · annulé' : ''}'),
                trailing: Text('${entree ? '+' : '−'} ${montant(m['amount'] as num?)}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: entree ? p.succes : null).merge(chiffresFixes)),
                onLongPress: annule || m['source_type'] != null
                    ? null
                    : () async {
                        final motif = await confirmer(context,
                            titre: 'Annuler le mouvement', message: 'Seuls les mouvements saisis à la main peuvent être annulés.', motif: true, danger: true);
                        if (motif == null || !context.mounted) return;
                        await executer(context, () => api.post<dynamic>('/caisse/${m['id']}/annuler', body: {'reason': motif}), succes: 'Mouvement annulé');
                        setState(() => _version++);
                      },
              );
            },
          ),
        ),
      ]),
    );
  }
}
