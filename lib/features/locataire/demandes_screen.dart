import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/referentiels.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/formulaire.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../commun/documents.dart';

/// « Signaler un problème » et « Mes demandes » (§ 22, § 28) ; états des lieux à valider (§ 52).
class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  final _incidents = GlobalKey<ListePagineeState>();

  /// Baux actifs du locataire : avec plusieurs locations en cours, l'API exige
  /// le `lease_id` du logement concerné (sinon 422 BAIL_A_PRECISER).
  Future<List<OptionRef>> _logementsActifs() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/locataire/logement');
      return [
        for (final b in ((r['leases'] as List?) ?? []).cast<Map>())
          if (b['status'] == 'actif')
            OptionRef('${b['id']}', [
              (b['apartment'] as Map?)?['building'] is Map ? '${((b['apartment'] as Map)['building'] as Map)['name']}' : null,
              (b['apartment'] as Map?)?['number'] != null ? 'Appartement ${(b['apartment'] as Map)['number']}' : null,
            ].whereType<String>().join(' · ')),
      ];
    } catch (_) {
      // Hors ligne sans cache : l'API tranchera (bail unique) à la synchronisation
      return const [];
    }
  }

  Future<void> _signaler() async {
    final logements = await _logementsActifs();
    if (!mounted) return;
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Signaler un problème',
        intro: const Text('Décrivez le problème : votre propriétaire est prévenu immédiatement. Vous pourrez ajouter des photos ensuite.'),
        champs: [
          if (logements.length > 1)
            Champ('lease_id', 'Logement concerné', type: TypeChamp.selection, options: logements, obligatoire: true),
          const Champ('category', 'Type de problème', type: TypeChamp.selection, referentiel: 'categorie_incident', obligatoire: true),
          const Champ('title', 'En quelques mots', obligatoire: true, maxLongueur: 150, indice: 'Ex. Fuite sous l’évier'),
          const Champ('description', 'Description', type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 5000),
        ],
        libelleEnvoi: 'Envoyer',
        envoyer: (c) async {
          final r = await Services.fileAttente.envoyerOuDifferer<Map<String, dynamic>>(
            libelle: 'Signalement : ${c['title']}',
            chemin: '/locataire/incidents',
            corps: {...c, 'client_reference': 'inc-${nouvelleCle()}'},
          );
          return r?['incident'] ?? 'differe';
        },
      ),
    );
    if (r == null || !mounted) return;
    if (r == 'differe') {
      afficherSucces(context, 'Hors ligne : votre signalement sera envoyé au retour du réseau.');
      return;
    }
    afficherSucces(context, 'Signalement envoyé');
    _incidents.currentState?.recharger();
    await ouvrir(context, IncidentLocataire(id: '${(r as Map)['id']}'));
    _incidents.currentState?.recharger();
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes'),
        bottom: TabBar(
          controller: _onglets,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [Tab(text: 'Problèmes signalés'), Tab(text: 'États des lieux')],
        ),
      ),
      floatingActionButton: _onglets.index == 0
          ? FloatingActionButton.extended(onPressed: _signaler, icon: const Icon(Icons.report_problem_outlined), label: const Text('Signaler un problème'))
          : null,
      body: TabBarView(controller: _onglets, children: [
        ListePaginee(
          key: _incidents,
          vide: 'Aucun problème signalé',
          iconeVide: Icons.build_circle_outlined,
          charger: (page) => api.get('/locataire/incidents', query: {'page': page}),
          element: (context, i) => ListTile(
            title: Text('${i['title']}'),
            subtitle: Text('${i['reference']} · ${refs.libelle('categorie_incident', i['category'] as String?)} · ${ilYa(i['created_at'] as String?)}'),
            trailing: Statut(FamilleStatut.incident, 'statut_incident', i['status'] as String?),
            onTap: () async {
              await ouvrir(context, IncidentLocataire(id: '${i['id']}'));
              _incidents.currentState?.recharger();
            },
          ),
        ),
        ListePaginee(
          vide: 'Aucun état des lieux',
          iconeVide: Icons.fact_check_outlined,
          charger: (page) => api.get('/locataire/etats-des-lieux', query: {'page': page, 'tri': '-created_at'}),
          element: (context, e) => ListTile(
            title: Text('${refs.libelle('type_etat_des_lieux', e['type'] as String?)} · version ${e['version']}'),
            subtitle: Text(e['status'] == 'soumis'
                ? 'À accepter ou contester avant le ${dateHeure(e['response_deadline'] as String?)}'
                : date((e['performed_at'] ?? e['submitted_at']) as String?)),
            trailing: Statut(FamilleStatut.etatDesLieux, 'statut_etat_des_lieux', e['status'] as String?),
            onTap: () => ouvrir(context, EtatDesLieuxLocataire(id: '${e['id']}')),
          ),
        ),
      ]),
    );
  }
}

class IncidentLocataire extends StatelessWidget {
  const IncidentLocataire({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Signalement',
      charger: () => api.get<Map<String, dynamic>>('/locataire/incidents/$id', cache: false),
      builder: (context, data, recharger) {
        final i = data['incident'] as Map;
        final docs = ((i['documents'] as List?) ?? []).cast<Map>();
        final ouvert = !['resolu', 'rejete'].contains(i['status']);

        Future<void> ajouter({bool video = false}) async {
          final XFile? f = video ? await ImagePicker().pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60)) : await choisirPhoto(context);
          if (f == null || !context.mounted) return;
          await executer(context, () => api.upload<dynamic>('/locataire/incidents/$id/pieces', cheminFichier: f.path, idempotence: nouvelleCle()),
              succes: video ? 'Vidéo ajoutée' : 'Photo ajoutée');
          recharger();
        }

        return Scaffold(
          appBar: AppBar(title: Text('${i['reference']}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Row(children: [
                Expanded(child: Text('${i['title']}', style: Theme.of(context).textTheme.titleMedium)),
                Statut(FamilleStatut.incident, 'statut_incident', i['status'] as String?),
              ]),
              const SizedBox(height: 8),
              Text('${i['description']}'),
              const SizedBox(height: 8),
              Ligne('Type', refs.libelle('categorie_incident', i['category'] as String?)),
              Ligne('Signalé le', dateHeure(i['created_at'] as String?)),
              if (i['analysed_at'] != null) Ligne('Pris en charge le', dateHeure(i['analysed_at'] as String?)),
              if (i['resolved_at'] != null) Ligne('Résolu le', dateHeure(i['resolved_at'] as String?)),
              if (i['rejection_reason'] != null) Ligne('Motif du rejet', '${i['rejection_reason']}'),
            ]),
            const SizedBox(height: AppTheme.espaceLg),
            Section(titre: 'Photos et vidéos', children: [
              if (docs.isEmpty) const Text('Aucune pièce jointe'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final d in docs)
                  InkWell(
                    onTap: () => ouvrirDocument(context, d),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.rayon),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: '${d['mime_type']}'.startsWith('image/') ? ImageApi('${d['id']}') : const Icon(Icons.videocam_outlined),
                      ),
                    ),
                  ),
              ]),
              if (ouvert) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  OutlinedButton.icon(onPressed: () => ajouter(), icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Photo')),
                  OutlinedButton.icon(onPressed: () => ajouter(video: true), icon: const Icon(Icons.videocam_outlined), label: const Text('Vidéo')),
                ]),
              ],
            ]),
            if (((i['work_orders'] as List?) ?? []).isNotEmpty) ...[
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Intervention prévue', children: [
                for (final w in (i['work_orders'] as List).cast<Map>())
                  Ligne('${w['title'] ?? 'Travaux'}', null, widget: Statut(FamilleStatut.travaux, 'statut_travaux', w['status'] as String?)),
              ]),
            ],
          ]),
        );
      },
    );
  }
}

/// État des lieux côté locataire : consulter, accepter ou contester dans le délai (§ 52).
class EtatDesLieuxLocataire extends StatelessWidget {
  const EtatDesLieuxLocataire({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'État des lieux',
      charger: () => api.get<Map<String, dynamic>>('/locataire/etats-des-lieux/$id', cache: false),
      builder: (context, data, recharger) {
        final e = data['inspection'] as Map;
        final pieces = ((e['rooms'] as List?) ?? []).cast<Map>();
        final aRepondre = e['status'] == 'soumis';
        return Scaffold(
          appBar: AppBar(
            title: Text(refs.libelle('type_etat_des_lieux', e['type'] as String?)),
            actions: [
              IconButton(
                tooltip: 'PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => ouvrirPdf(context, '/locataire/etats-des-lieux/$id/pdf', 'etat-des-lieux-${e['type']}-v${e['version']}.pdf'),
              ),
            ],
          ),
          bottomNavigationBar: aRepondre
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final texte = await confirmer(context,
                                titre: "Contester l'état des lieux",
                                message: 'Expliquez précisément ce qui ne correspond pas (10 caractères minimum).',
                                motif: true,
                                libelleMotif: 'Votre commentaire',
                                minMotif: 10,
                                danger: true,
                                action: 'Contester');
                            if (texte == null || !context.mounted) return;
                            await executer(context, () => api.post<dynamic>('/locataire/etats-des-lieux/$id/contester', body: {'comment': texte}, idempotence: nouvelleCle()),
                                succes: 'Contestation envoyée');
                            recharger();
                          },
                          child: const Text('Contester'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final ok = await confirmer(context,
                                titre: "Accepter l'état des lieux", message: 'Vous confirmez que ce document correspond à l’état du logement.', action: 'Accepter');
                            if (ok == null || !context.mounted) return;
                            await executer(context, () => api.post<dynamic>('/locataire/etats-des-lieux/$id/accepter', idempotence: nouvelleCle()),
                                succes: 'État des lieux accepté');
                            recharger();
                          },
                          child: const Text('Accepter'),
                        ),
                      ),
                    ]),
                  ),
                )
              : null,
          body: ListView(padding: const EdgeInsets.all(16), children: [
            if (aRepondre) ...[
              Encadre('Sans réponse avant le ${dateHeure(e['response_deadline'] as String?)}, il sera considéré comme accepté.', ton: TonStatut.avertissement),
              const SizedBox(height: 12),
            ],
            Section(children: [
              Ligne('Statut', null, widget: Statut(FamilleStatut.etatDesLieux, 'statut_etat_des_lieux', e['status'] as String?)),
              Ligne('Date', date(e['performed_at'] as String?)),
              Ligne('Compteur d’eau', e['water_meter'] == null ? null : '${e['water_meter']} m³'),
              Ligne('Compteur d’électricité', e['electricity_meter'] == null ? null : '${e['electricity_meter']} kWh'),
              Ligne('Clés', e['keys_count'] == null ? null : '${e['keys_count']}'),
              if (e['general_observations'] != null) Ligne('Observations', '${e['general_observations']}'),
              if (e['contest_comment'] != null) Ligne('Votre contestation', '${e['contest_comment']}'),
            ]),
            const SizedBox(height: 12),
            for (final p in pieces)
              Card(
                child: ExpansionTile(
                  title: Text('${p['name']}'),
                  children: [
                    for (final it in ((p['items'] as List?) ?? []).cast<Map>())
                      ListTile(
                        dense: true,
                        title: Text(refs.libelle('element_etat_des_lieux', it['element'] as String?)),
                        subtitle: it['comment'] == null ? null : Text('${it['comment']}'),
                        trailing: Text(refs.libelle('etat_element', it['condition'] as String?)),
                        onTap: ((it['photos'] as List?) ?? []).isEmpty
                            ? null
                            : () => afficherImage(context, '${(((it['photos'] as List).first as Map)['document'] as Map)['id']}'),
                      ),
                  ],
                ),
              ),
          ]),
        );
      },
    );
  }
}
