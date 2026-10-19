import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/referentiels.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';

/// Cautions (§ 55) : versées, détenues, retenues (justifiées), restituées ou en litige.
class CautionsScreen extends StatefulWidget {
  const CautionsScreen({super.key});

  @override
  State<CautionsScreen> createState() => _CautionsScreenState();
}

class _CautionsScreenState extends State<CautionsScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  String _statut = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cautions')),
      body: Column(children: [
        Filtres(
          options: [('', 'Toutes'), for (final o in refs.options('statut_caution')) (o.code, o.label)],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _statut,
            vide: 'Aucune caution',
            iconeVide: Icons.savings_outlined,
            charger: (page) => api.get('/cautions', query: {'page': page, 'status': _statut, 'tri': '-created_at'}),
            element: (context, c) => ListTile(
              title: Text('${nomComplet(c['tenant'] as Map?)} · ${(c['lease'] as Map?)?['reference'] ?? ''}'),
              subtitle: Text('Reçu ${montant(c['amount_received'] as num?)} sur ${montant(c['amount_expected'] as num?)}'),
              trailing: Statut(FamilleStatut.caution, 'statut_caution', c['status'] as String?),
              onTap: () async {
                await ouvrir(context, CautionDetail(id: '${c['id']}'));
                _liste.currentState?.recharger();
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class CautionDetail extends StatelessWidget {
  const CautionDetail({super.key, required this.id});
  final String id;

  Future<void> _mouvement(BuildContext context, String type, Map c, VoidCallback recharger) async {
    final cle = nouvelleCle();
    final solde = entier(c['balance']);
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: type == 'versement' ? 'Versement de caution' : 'Restitution de caution',
        initial: {
          'occurred_on': aujourdhui(),
          'method': 'especes',
          'amount': type == 'versement' ? entier(c['amount_expected']) - entier(c['amount_received']) : solde,
        },
        intro: type == 'restitution' ? Text('Solde détenu : ${montant(solde)}') : null,
        champs: const [
          Champ('amount', 'Montant', type: TypeChamp.montant, obligatoire: true, min: 1),
          Champ('method', 'Moyen', type: TypeChamp.selection, referentiel: 'mode_paiement', obligatoire: true),
          Champ('occurred_on', 'Date', type: TypeChamp.date, obligatoire: true),
          Champ('reference', 'Référence', maxLongueur: 64),
        ],
        messageSucces: type == 'versement' ? 'Versement enregistré' : 'Restitution enregistrée',
        envoyer: (corps) => api.post<Map<String, dynamic>>('/cautions/$id/${type == 'versement' ? 'versements' : 'restitutions'}',
            body: corps, idempotence: cle),
      ),
    );
    if (r != null) recharger();
  }

  /// Retenue : un motif ET au moins un justificatif sont exigés (§ 55.4).
  Future<void> _retenue(BuildContext context, VoidCallback recharger) async {
    final photo = await choisirPhoto(context);
    if (photo == null || !context.mounted) return;
    final doc = await executer(context, () => api.upload<Map<String, dynamic>>('/cautions/$id/justificatifs', cheminFichier: photo.path, idempotence: nouvelleCle()));
    if (doc == null || !context.mounted) return;
    final docId = '${(doc['document'] as Map)['id']}';
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Retenue sur caution',
        intro: const Encadre('Justificatif joint. Le locataire est informé et peut contester la retenue.'),
        initial: {'occurred_on': aujourdhui()},
        champs: const [
          Champ('amount', 'Montant retenu', type: TypeChamp.montant, obligatoire: true, min: 1),
          Champ('reason', 'Motif', type: TypeChamp.selection, referentiel: 'motif_retenue', obligatoire: true),
          Champ('description', 'Explication', type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 2000, indice: '5 caractères minimum'),
          Champ('occurred_on', 'Date', type: TypeChamp.date),
        ],
        libelleEnvoi: 'Enregistrer la retenue',
        messageSucces: 'Retenue enregistrée',
        envoyer: (corps) => api.post<Map<String, dynamic>>('/cautions/$id/retenues',
            body: {...corps, 'justification_document_ids': [docId]}, idempotence: cle),
      ),
    );
    if (r != null) recharger();
  }

  Future<void> _repondre(BuildContext context, Map t, VoidCallback recharger) async {
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Répondre à la contestation',
        intro: Text('« ${t['contest_message']} »'),
        champs: [
          Champ('outcome', 'Décision', type: TypeChamp.selection, obligatoire: true, options: [
            for (final o in refs.options('statut_contestation').where((o) => o.code != 'conteste')) OptionRef(o.code, o.label),
          ]),
          Champ('adjusted_amount', 'Nouveau montant retenu', type: TypeChamp.montant, visible: (v) => v['outcome'] == 'ajustee'),
          const Champ('response', 'Réponse au locataire', type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 4000),
        ],
        libelleEnvoi: 'Envoyer la réponse',
        messageSucces: 'Réponse envoyée',
        envoyer: (corps) => api.post<Map<String, dynamic>>('/cautions/$id/retenues/${t['id']}/reponse', body: corps),
      ),
    );
    if (r != null) recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Caution',
      charger: () => api.get<Map<String, dynamic>>('/cautions/$id'),
      builder: (context, data, recharger) {
        final c = data['deposit'] as Map;
        final bail = c['lease'] as Map? ?? {};
        final termine = ['termine', 'clos'].contains(bail['status']);
        final transactions = ((c['transactions'] as List?) ?? []).cast<Map>();
        final aVerser = entier(c['amount_expected']) - entier(c['amount_received']);
        return Scaffold(
          appBar: AppBar(title: Text('Caution · ${nomComplet(c['tenant'] as Map?)}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Row(children: [
                Expanded(child: Text('${bail['reference'] ?? ''}', style: Theme.of(context).textTheme.titleMedium)),
                Statut(FamilleStatut.caution, 'statut_caution', c['status'] as String?),
              ]),
              const SizedBox(height: AppTheme.espaceSm),
              Ligne('Attendue', montant(c['amount_expected'] as num?)),
              Ligne('Reçue', montant(c['amount_received'] as num?)),
              Ligne('Retenue', montant(c['amount_withheld'] as num?)),
              Ligne('Restituée', montant(c['amount_refunded'] as num?)),
              const Divider(),
              Ligne('Solde détenu', null, widget: Montant(c['balance'] as num?, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18))),
              if (c['refund_due_date'] != null) Ligne('À restituer avant le', date(c['refund_due_date'] as String?)),
            ]),
            const SizedBox(height: AppTheme.espaceLg),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (aVerser > 0)
                FilledButton.icon(
                  onPressed: () => _mouvement(context, 'versement', c, recharger),
                  icon: const Icon(Icons.add),
                  label: const Text('Enregistrer un versement'),
                ),
              if (termine && entier(c['balance']) > 0) ...[
                OutlinedButton.icon(onPressed: () => _retenue(context, recharger), icon: const Icon(Icons.remove), label: const Text('Retenue justifiée')),
                OutlinedButton.icon(
                  onPressed: () => _mouvement(context, 'restitution', c, recharger),
                  icon: const Icon(Icons.undo),
                  label: const Text('Restituer'),
                ),
              ],
            ]),
            if (!termine && entier(c['balance']) > 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Encadre('Retenues et restitution sont possibles une fois le bail terminé.'),
              ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(titre: 'Mouvements', padding: false, children: [
              if (transactions.isEmpty) const ListTile(title: Text('Aucun mouvement')),
              for (final t in transactions)
                ListTile(
                  title: Text('${refs.libelle('type_mouvement_caution', t['type'] as String?)}'
                      '${t['reason'] != null ? ' · ${refs.libelle('motif_retenue', t['reason'] as String?)}' : ''}'),
                  subtitle: Text([
                    date(t['occurred_on'] as String?),
                    if (t['description'] != null) '${t['description']}',
                    if (t['contest_status'] != null) 'Contestation : ${refs.libelle('statut_contestation', t['contest_status'] as String?)}',
                  ].join('\n')),
                  isThreeLine: t['description'] != null || t['contest_status'] != null,
                  trailing: Montant(t['amount'] as num?),
                  onTap: t['contest_status'] == 'conteste' ? () => _repondre(context, t, recharger) : null,
                ),
            ]),
            if (transactions.any((t) => t['contest_status'] == 'conteste'))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Encadre('Une retenue est contestée par le locataire : touchez-la pour répondre.', ton: TonStatut.danger),
              ),
            const SizedBox(height: AppTheme.espaceLg),
            SectionDocuments(type: 'deposit', ajout: false, id: id, titre: 'Justificatifs'),
          ]),
        );
      },
    );
  }
}
