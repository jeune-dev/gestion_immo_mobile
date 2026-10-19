import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';
import '../finances/cautions_screen.dart';
import '../finances/echeances_screen.dart';
import '../finances/encaissement.dart';
import '../travaux/etats_des_lieux.dart';
import 'formulaires.dart';
import 'locataire_detail.dart';

/// Contrat de location (§ 10) et son cycle : brouillon → actif → terminé → clos.
class BailDetail extends StatelessWidget {
  const BailDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<List<dynamic>>(
      page: true,
      titre: 'Bail',
      charger: () => Future.wait([
        api.get<Map<String, dynamic>>('/baux/$id'),
        api.get<Map<String, dynamic>>('/baux/$id/contrats'),
      ]),
      builder: (context, data, recharger) {
        final b = Map<String, dynamic>.from((data[0] as Map)['lease'] as Map);
        final contrats = ((data[1] as Map)['contracts'] as List).cast<Map>();
        final statut = b['status'] as String;
        final tenant = b['tenant'] as Map? ?? {};
        final app = b['apartment'] as Map? ?? {};
        final caution = b['deposit'] as Map?;
        final solde = b['balance'] as Map? ?? {};
        final inspections = ((b['inspections'] as List?) ?? []).cast<Map>();

        Future<void> action(Future<dynamic> Function() f, String succes) async {
          await executer(context, f, succes: succes);
          recharger();
        }

        final actions = <(String, VoidCallback, bool)>[
          if (statut == 'brouillon')
            ('Modifier', () async {
              if (await FormulairesBiens.bail(context, existant: b) != null) recharger();
            }, false),
          if (statut == 'actif')
            ('Réviser le loyer', () async {
              final r = await EcranFormulaire.ouvrir<Map>(
                context,
                EcranFormulaire(
                  titre: 'Réviser le loyer',
                  intro: const Text('Les échéances à partir de la date d’effet sont recalculées. La date ne peut pas être passée.'),
                  initial: {'rent_amount': b['rent_amount'], 'charges_amount': b['charges_amount']},
                  champs: const [
                    Champ('rent_amount', 'Nouveau loyer', type: TypeChamp.montant),
                    Champ('charges_amount', 'Nouvelles charges', type: TypeChamp.montant),
                    Champ('effective_from', "Date d'effet", type: TypeChamp.date, obligatoire: true),
                  ],
                  messageSucces: 'Loyer révisé',
                  envoyer: (c) => api.post<Map<String, dynamic>>('/baux/$id/loyer', body: c),
                ),
              );
              if (r != null) recharger();
            }, false),
          if (statut == 'actif')
            ('Mettre fin au bail', () async {
              final r = await EcranFormulaire.ouvrir<Map>(
                context,
                EcranFormulaire(
                  titre: 'Fin du bail',
                  intro: const Text("L'appartement redevient disponible. La caution sera ensuite restituée ou retenue avant la clôture."),
                  initial: {'ended_on': aujourdhui()},
                  champs: const [
                    Champ('ended_on', 'Date de sortie', type: TypeChamp.date, obligatoire: true),
                    Champ('termination_reason', 'Motif', type: TypeChamp.multiligne, maxLongueur: 1000),
                  ],
                  libelleEnvoi: 'Mettre fin au bail',
                  messageSucces: 'Bail terminé',
                  envoyer: (c) => api.post<Map<String, dynamic>>('/baux/$id/terminer', body: c),
                ),
              );
              if (r != null) recharger();
            }, true),
          if (statut == 'termine')
            ('Clôturer le bail', () async {
              final ok = await confirmer(context,
                  titre: 'Clôturer le bail',
                  message: 'Possible seulement quand la caution est restituée ou que le litige est documenté.',
                  action: 'Clôturer');
              if (ok != null) await action(() => api.post<dynamic>('/baux/$id/cloturer'), 'Bail clôturé');
            }, false),
          if (statut == 'brouillon')
            ('Annuler le bail', () async {
              final motif = await confirmer(context,
                  titre: 'Annuler le bail', message: 'Le brouillon sera annulé.', action: 'Annuler le bail', danger: true, motif: true);
              if (motif != null) await action(() => api.post<dynamic>('/baux/$id/annuler', body: {'reason': motif}), 'Bail annulé');
            }, true),
        ];

        return Scaffold(
          appBar: AppBar(title: Text('${b['reference']}'), actions: [MenuActions(actions: actions)]),
          floatingActionButton: statut == 'brouillon'
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final ok = await confirmer(context,
                        titre: 'Activer le bail',
                        message: "L'appartement passe « Occupé », les échéances sont générées sur 12 mois et la caution est ouverte.",
                        action: 'Activer');
                    if (ok == null || !context.mounted) return;
                    final r = await executer(context, () => api.post<Map<String, dynamic>>('/baux/$id/activer'), succes: 'Bail activé');
                    final avertissements = ((r?['avertissements'] as List?) ?? []).cast<Map>();
                    if (avertissements.isNotEmpty && context.mounted) {
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('À noter'),
                          content: Text(avertissements.map((a) => '• ${a['message']}').join('\n')),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    }
                    recharger();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Activer le bail'),
                )
              : statut == 'actif'
                  ? FloatingActionButton.extended(
                      onPressed: () async {
                        if (await encaisser(context, bail: b) != null) recharger();
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Encaisser'),
                    )
                  : null,
          body: RefreshIndicator(
            onRefresh: recharger,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
              Section(children: [
                Row(children: [
                  Expanded(child: Text(refs.libelle('type_bail', b['lease_type'] as String?), style: Theme.of(context).textTheme.titleMedium)),
                  Statut(FamilleStatut.bail, 'statut_bail', statut),
                ]),
                const SizedBox(height: AppTheme.espaceSm),
                Ligne('Locataire', null,
                    widget: TextButton(
                      onPressed: () => ouvrir(context, LocataireDetail(id: '${tenant['id']}')),
                      child: Text(nomComplet(tenant)),
                    )),
                Ligne('Logement', 'Appartement ${app['number'] ?? ''} · ${(app['building'] as Map?)?['name'] ?? ''}'),
                Ligne('Période', '${date(b['start_date'] as String?)} → ${b['end_date'] == null ? 'durée indéterminée' : date(b['end_date'] as String?)}'),
                if (b['ended_on'] != null) Ligne('Sorti le', date(b['ended_on'] as String?)),
                Ligne('Loyer', '${montant(b['rent_amount'] as num?)} · ${refs.libelle('periodicite', b['periodicity'] as String?)}'),
                Ligne('Charges', montant(b['charges_amount'] as num?)),
                Ligne("Jour d'échéance", 'le ${b['due_day']}'),
                Ligne('Préavis', '${b['notice_period_months']} mois'),
                if (b['special_conditions'] != null) Ligne('Conditions particulières', '${b['special_conditions']}'),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              if (statut != 'brouillon')
                Section(
                  titre: 'Loyers',
                  action: TextButton(onPressed: () => ouvrir(context, EcheancesScreen(bailId: id, titre: '${b['reference']}')), child: const Text('Échéances')),
                  children: [
                    Ligne('Reste dû', null,
                        widget: Montant(solde['reste_du'] as num?,
                            style: TextStyle(fontWeight: FontWeight.w600, color: entier(solde['reste_du']) > 0 ? context.palette.danger : null))),
                    Ligne('Total encaissé', montant(solde['total_encaisse'] as num?)),
                  ],
                ),
              if (caution != null) ...[
                const SizedBox(height: AppTheme.espaceLg),
                Section(titre: 'Caution', padding: false, children: [
                  ListTile(
                    title: Text('${montant(caution['amount_received'] as num?)} reçus sur ${montant(caution['amount_expected'] as num?)}'),
                    subtitle: entier(caution['amount_withheld']) + entier(caution['amount_refunded']) > 0
                        ? Text('Retenu ${montant(caution['amount_withheld'] as num?)} · restitué ${montant(caution['amount_refunded'] as num?)}')
                        : null,
                    trailing: Statut(FamilleStatut.caution, 'statut_caution', caution['status'] as String?),
                    onTap: () async {
                      await ouvrir(context, CautionDetail(id: '${caution['id']}'));
                      recharger();
                    },
                  ),
                ]),
              ],
              const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: 'États des lieux',
                padding: false,
                action: statut == 'annule' || statut == 'clos'
                    ? null
                    : TextButton(
                        onPressed: () async {
                          final type = statut == 'brouillon' ? 'entree' : statut == 'termine' ? 'sortie' : null;
                          final cree = await EtatsDesLieux.creer(context, bailId: id, type: type);
                          if (cree != null) recharger();
                        },
                        child: const Text('Nouveau'),
                      ),
                children: [
                  if (inspections.isEmpty) const ListTile(title: Text('Aucun état des lieux')),
                  for (final i in inspections)
                    ListTile(
                      title: Text('${refs.libelle('type_etat_des_lieux', i['type'] as String?)} · version ${i['version']}'),
                      subtitle: Text(date((i['performed_at'] ?? i['created_at']) as String?)),
                      trailing: Statut(FamilleStatut.etatDesLieux, 'statut_etat_des_lieux', i['status'] as String?),
                      onTap: () async {
                        await ouvrir(context, EtatDesLieuxDetail(id: '${i['id']}'));
                        recharger();
                      },
                    ),
                  if (inspections.any((i) => i['type'] == 'sortie'))
                    TextButton(onPressed: () => ouvrir(context, ComparaisonEdl(bailId: id)), child: const Text('Comparer entrée et sortie')),
                ],
              ),
              const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: 'Contrat de bail',
                padding: false,
                action: statut == 'annule'
                    ? null
                    : TextButton(
                        onPressed: () async {
                          final cle = nouvelleCle();
                          final r = await EcranFormulaire.ouvrir<Map>(
                            context,
                            EcranFormulaire(
                              titre: 'Générer le contrat',
                              intro: const Text('Le contrat est produit en PDF à partir du modèle de bail publié (conforme OHADA) et partagé au locataire.'),
                              champs: const [Champ('special_clauses', 'Clauses particulières', type: TypeChamp.multiligne, maxLongueur: 10000)],
                              libelleEnvoi: 'Générer',
                              messageSucces: 'Contrat généré',
                              envoyer: (c) => api.post<Map<String, dynamic>>('/baux/$id/contrats', body: c, idempotence: cle),
                            ),
                          );
                          if (r != null) recharger();
                        },
                        child: const Text('Générer'),
                      ),
                children: [
                  if (contrats.isEmpty) const ListTile(title: Text('Aucun contrat généré')),
                  for (final c in contrats)
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Contrat version ${c['version']}'),
                      subtitle: Text('Modèle v${c['template_version']} · ${date(c['created_at'] as String?)}'),
                      trailing: IconButton(
                        tooltip: 'Partager',
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => ouvrirPdf(context, '/documents/${c['document_id']}/fichier', 'contrat-${b['reference']}-v${c['version']}.pdf', partager: true),
                      ),
                      onTap: () => ouvrirPdf(context, '/documents/${c['document_id']}/fichier', 'contrat-${b['reference']}-v${c['version']}.pdf'),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.espaceLg),
              SectionDocuments(type: 'lease', id: id),
              if (statut == 'termine') ...[
                const SizedBox(height: AppTheme.espaceLg),
                const Encadre('Bail terminé : réglez la caution (restitution ou retenue justifiée) puis clôturez le bail depuis le menu.',
                    ton: TonStatut.avertissement),
              ],
            ]),
          ),
        );
      },
    );
  }
}
