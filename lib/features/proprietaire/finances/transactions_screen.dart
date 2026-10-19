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

/// Paiements en ligne (Wave, Orange Money via PayDunya) et paiements directs
/// déclarés avec une preuve, que le propriétaire valide ou rejette (§ 12, § 51).
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.aValider = false});
  final bool aValider;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  late String _statut = widget.aValider ? 'en_attente' : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements en ligne')),
      body: Column(children: [
        Filtres(
          options: [('', 'Toutes'), for (final o in refs.options('statut_transaction')) (o.code, o.label)],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _statut,
            vide: 'Aucune transaction',
            charger: (page) => api.get('/paiements/transactions', query: {
              'page': page,
              'status': _statut,
              if (widget.aValider) 'mode': 'preuve',
              'tri': '-created_at',
            }),
            element: (context, t) => ListTile(
              title: Text('${nomComplet(t['tenant'] as Map?)} · ${refs.libelle('portefeuille', t['wallet'] as String?)}'),
              subtitle: Text('${refs.libelle('mode_transaction', t['mode'] as String?)} · ${(t['schedule'] as Map?)?['label'] ?? ''} · ${dateHeure(t['created_at'] as String?)}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Montant(t['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
                Statut(FamilleStatut.transaction, 'statut_transaction', t['status'] as String?),
              ]),
              onTap: () async {
                await ouvrir(context, TransactionDetail(id: '${t['id']}'));
                _liste.currentState?.recharger();
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class TransactionDetail extends StatelessWidget {
  const TransactionDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Transaction',
      charger: () => api.get<Map<String, dynamic>>('/paiements/transactions/$id'),
      builder: (context, data, recharger) {
        final t = data['transaction'] as Map;
        final preuve = t['proof'] as Map?;
        final aValider = t['mode'] == 'preuve' && t['status'] == 'en_attente';
        return Scaffold(
          appBar: AppBar(title: Text('${t['reference']}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Ligne('Montant', null, widget: Montant(t['amount'] as num?, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              Ligne('Statut', null, widget: Statut(FamilleStatut.transaction, 'statut_transaction', t['status'] as String?)),
              Ligne('Locataire', nomComplet(t['tenant'] as Map?)),
              Ligne('Échéance', '${(t['schedule'] as Map?)?['label'] ?? '—'}'),
              Ligne('Portefeuille', refs.libelle('portefeuille', t['wallet'] as String?)),
              Ligne('Mode', refs.libelle('mode_transaction', t['mode'] as String?)),
              Ligne('N° de transaction', t['provider_transaction_id'] as String?),
              Ligne('Téléphone payeur', t['payer_phone'] as String?),
              Ligne('Créée le', dateHeure(t['created_at'] as String?)),
              if (t['rejection_reason'] != null) Ligne('Motif du rejet', '${t['rejection_reason']}'),
              if ((t['payment'] as Map?) != null) Ligne('Paiement', '${(t['payment'] as Map)['reference']}'),
            ]),
            if (preuve != null) ...[
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Preuve de paiement', children: [
                InkWell(
                  onTap: () => ouvrirDocument(context, preuve),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.rayon),
                    child: SizedBox(
                      height: 220,
                      child: '${preuve['mime_type']}'.startsWith('image/')
                          ? ImageApi('${preuve['id']}', taille: 'originale', fit: BoxFit.contain)
                          : const Center(child: Icon(Icons.picture_as_pdf_outlined, size: 48)),
                    ),
                  ),
                ),
              ]),
            ],
            if (aValider) ...[
              const SizedBox(height: AppTheme.espaceLg),
              const Encadre('Vérifiez sur votre relevé Wave / Orange Money que ce montant a bien été reçu avant de valider.'),
              const SizedBox(height: AppTheme.espaceLg),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await confirmer(context,
                      titre: 'Valider le paiement', message: 'Le paiement sera enregistré et la quittance générée.', action: 'Valider');
                  if (ok == null || !context.mounted) return;
                  await executer(context, () => api.post<dynamic>('/paiements/transactions/$id/valider', idempotence: nouvelleCle()),
                      succes: 'Paiement validé');
                  recharger();
                },
                icon: const Icon(Icons.check),
                label: const Text('Valider le paiement'),
              ),
              const SizedBox(height: AppTheme.espaceSm),
              OutlinedButton.icon(
                onPressed: () async {
                  final motif = await confirmer(context,
                      titre: 'Rejeter la preuve', message: 'Le locataire sera informé du motif.', action: 'Rejeter', danger: true, motif: true);
                  if (motif == null || !context.mounted) return;
                  await executer(context, () => api.post<dynamic>('/paiements/transactions/$id/rejeter', body: {'reason': motif}),
                      succes: 'Preuve rejetée');
                  recharger();
                },
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
              ),
            ],
          ]),
        );
      },
    );
  }
}

/// File « À rapprocher » (§ 51.3) : paiements non identifiés et excédents.
class RapprochementsScreen extends StatefulWidget {
  const RapprochementsScreen({super.key});

  @override
  State<RapprochementsScreen> createState() => _RapprochementsScreenState();
}

class _RapprochementsScreenState extends State<RapprochementsScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  String _statut = 'en_attente';

  Future<void> _traiter(Map<String, dynamic> e) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(e['type'] == 'excedent' ? 'Imputer le crédit à une échéance' : 'Rattacher à un bail'),
            onTap: () => Navigator.pop(ctx, 'resoudre'),
          ),
          ListTile(leading: const Icon(Icons.undo), title: const Text('Rejeter et rembourser'), onTap: () => Navigator.pop(ctx, 'rejeter')),
        ]),
      ),
    );
    if (choix == null || !mounted) return;
    if (choix == 'resoudre') {
      final cle = nouvelleCle();
      final r = await EcranFormulaire.ouvrir<Map>(
        context,
        EcranFormulaire(
          titre: 'Rapprocher le paiement',
          intro: Text('${montant(e['amount'] as num?)} — ${refs.libelle('type_rapprochement', e['type'] as String?)}'),
          initial: {if (e['lease_id'] != null) 'lease_id': e['lease_id']},
          champs: [
            if (e['lease_id'] == null) Champ('lease_id', 'Bail', type: TypeChamp.entite, obligatoire: true, entite: Sources.baux()),
            if (e['lease_id'] != null)
              Champ('rent_schedule_id', 'Échéance (facultatif)', type: TypeChamp.entite, entite: Sources.echeancesImpayees('${e['lease_id']}')),
            const Champ('note', 'Note', type: TypeChamp.multiligne, maxLongueur: 1000),
          ],
          libelleEnvoi: 'Rapprocher',
          messageSucces: 'Paiement rapproché',
          envoyer: (c) => api.post<Map<String, dynamic>>('/paiements/rapprochements/${e['id']}/resoudre', body: c, idempotence: cle),
        ),
      );
      if (r != null) _liste.currentState?.recharger();
    } else {
      final r = await EcranFormulaire.ouvrir<Map>(
        context,
        EcranFormulaire(
          titre: 'Rejeter et rembourser',
          initial: const {'refund_method': 'especes'},
          champs: const [
            Champ('note', 'Motif', type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 1000),
            Champ('refund_method', 'Moyen du remboursement', type: TypeChamp.selection, referentiel: 'mode_paiement'),
          ],
          libelleEnvoi: 'Rejeter',
          messageSucces: 'Paiement rejeté',
          envoyer: (c) => api.post<Map<String, dynamic>>('/paiements/rapprochements/${e['id']}/rejeter', body: c),
        ),
      );
      if (r != null) _liste.currentState?.recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À rapprocher')),
      body: Column(children: [
        Filtres(
          options: [for (final o in refs.options('statut_rapprochement')) (o.code, o.label)],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _statut,
            vide: 'Rien à rapprocher',
            iconeVide: Icons.verified_outlined,
            charger: (page) => api.get('/paiements/rapprochements', query: {'page': page, 'status': _statut}),
            element: (context, e) {
              final details = (e['details'] as Map?) ?? {};
              return ListTile(
                title: Text(refs.libelle('type_rapprochement', e['type'] as String?)),
                subtitle: Text([
                  if (e['tenant'] != null) nomComplet(e['tenant'] as Map?),
                  if (e['payer_phone'] != null) '${e['payer_phone']}',
                  if (details['reference_recue'] != null) 'Réf. ${details['reference_recue']}',
                  dateHeure(e['created_at'] as String?),
                ].join(' · ')),
                trailing: Montant(e['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: e['status'] == 'en_attente' ? () => _traiter(e) : null,
              );
            },
          ),
        ),
      ]),
    );
  }
}
