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
import '../finances/depenses_screen.dart';
import 'travaux_hub_screen.dart';

/// Transitions permises (identiques à `config/transitions.js` côté API).
const transitionsTravaux = {
  'signale': ['a_valider', 'valide', 'annule'],
  'a_valider': ['valide', 'annule'],
  'valide': ['artisan_assigne', 'en_cours', 'annule'],
  'artisan_assigne': ['en_cours', 'valide', 'annule'],
  'en_cours': ['termine', 'annule'],
};

/// Fiche d'un chantier (§ 18–19) : statut historisé, photos avant / pendant / après, dépenses.
class TravauxDetail extends StatelessWidget {
  const TravauxDetail({super.key, required this.id});
  final String id;

  Future<void> _changerStatut(BuildContext context, Map t, String statut, VoidCallback recharger) async {
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: refs.libelle('statut_travaux', statut),
        initial: {
          if (t['contractor'] != null) 'contractor_id': t['contractor_id'],
          if (t['contractor'] != null) 'contractor_id__libelle': (t['contractor'] as Map)['name'],
          'actual_amount': t['actual_amount'] ?? t['estimated_amount'],
        },
        intro: statut == 'termine'
            ? const Text('Un chantier terminé est figé : son historique et ses photos ne pourront plus être modifiés.')
            : null,
        champs: [
          if (statut == 'artisan_assigne') Champ('contractor_id', 'Artisan', type: TypeChamp.entite, obligatoire: true, entite: Sources.artisans),
          if (statut == 'termine') const Champ('actual_amount', 'Coût réel', type: TypeChamp.montant),
          Champ('comment', statut == 'annule' ? 'Motif' : 'Commentaire', type: TypeChamp.multiligne, obligatoire: statut == 'annule', maxLongueur: 2000),
        ],
        libelleEnvoi: 'Confirmer',
        messageSucces: 'Statut mis à jour',
        envoyer: (c) => api.post<Map<String, dynamic>>('/travaux/$id/statut', body: {...c, 'status': statut}),
      ),
    );
    if (r != null) recharger();
  }

  Future<void> _photo(BuildContext context, String phase, VoidCallback recharger) async {
    final photo = await choisirPhoto(context);
    if (photo == null || !context.mounted) return;
    await executer(
      context,
      () => api.upload<dynamic>('/travaux/$id/photos',
          cheminFichier: photo.path, champs: {'phase': phase, 'captured_at': DateTime.now().toUtc().toIso8601String()}, idempotence: nouvelleCle()),
      succes: 'Photo ajoutée',
    );
    recharger();
  }

  Future<void> _supprimerPhoto(BuildContext context, Map p, VoidCallback recharger) async {
    final ok = await confirmer(context,
        titre: 'Retirer la photo', message: 'La photo sera supprimée du chantier.', action: 'Retirer', danger: true);
    if (ok == null || !context.mounted) return;
    final r = await executer(context, () => api.delete<dynamic>('/travaux/$id/photos/${p['id']}').then((_) => true), succes: 'Photo retirée');
    if (r == true) recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Travaux',
      charger: () => api.get<Map<String, dynamic>>('/travaux/$id'),
      builder: (context, data, recharger) {
        final t = Map<String, dynamic>.from(data['work_order'] as Map);
        final statut = t['status'] as String;
        final suivants = transitionsTravaux[statut] ?? const <String>[];
        final ferme = statut == 'termine' || statut == 'annule';
        final photos = (t['photos'] as Map?) ?? {};
        final depenses = ((t['expenses'] as List?) ?? []).cast<Map>();
        return Scaffold(
          appBar: AppBar(
            title: Text('${t['reference']}'),
            actions: [
              if (!ferme)
                MenuActions(actions: [
                  ('Modifier', () async {
                    if (await FormulairesTravaux.travaux(context, existant: t) != null) recharger();
                  }, false),
                  ('Ajouter une dépense', () async {
                    if (await nouvelleDepense(context, travaux: t)) recharger();
                  }, false),
                ]),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: recharger,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Section(children: [
                Row(children: [
                  Expanded(child: Text('${t['title']}', style: Theme.of(context).textTheme.titleMedium)),
                  Statut(FamilleStatut.travaux, 'statut_travaux', statut),
                ]),
                const SizedBox(height: AppTheme.espaceSm),
                Ligne('Immeuble', '${(t['building'] as Map?)?['name'] ?? ''}'),
                if (t['apartment'] != null) Ligne('Appartement', '${(t['apartment'] as Map)['number']}'),
                Ligne('Catégorie', refs.libelle('categorie_travaux', t['category'] as String?)),
                Ligne('Priorité', null, widget: Statut(FamilleStatut.priorite, 'priorite', t['priority'] as String?)),
                Ligne('Artisan', (t['contractor'] as Map?)?['name'] as String?),
                Ligne('Prévu le', date(t['scheduled_for'] as String?)),
                Ligne('Coût estimé', montant(t['estimated_amount'] as num?)),
                Ligne('Coût réel', montant(t['actual_amount'] as num?)),
                Ligne('Dépenses liées', montant(t['total_expenses'] as num?)),
                if (t['incident'] != null) Ligne('Incident', '${(t['incident'] as Map)['reference']}'),
                if (t['description'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${t['description']}')),
              ]),
              if (suivants.isNotEmpty) ...[
                const SizedBox(height: AppTheme.espaceLg),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in suivants)
                    s == 'annule'
                        ? TextButton(onPressed: () => _changerStatut(context, t, s, recharger), child: const Text('Annuler les travaux'))
                        : OutlinedButton(
                            onPressed: () => _changerStatut(context, t, s, recharger),
                            child: Text('→ ${refs.libelle('statut_travaux', s)}'),
                          ),
                ]),
              ],
              const SizedBox(height: AppTheme.espaceLg),
              for (final phase in ['avant', 'pendant', 'apres']) ...[
                Section(
                  titre: 'Photos ${refs.libelle('phase_photo', phase).toLowerCase()}',
                  action: ferme ? null : IconButton(tooltip: 'Ajouter', icon: const Icon(Icons.add_a_photo_outlined), onPressed: () => _photo(context, phase, recharger)),
                  children: [
                    if (((photos[phase] as List?) ?? []).isEmpty)
                      Text('Aucune photo', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                    else
                      SizedBox(
                        height: 96,
                        child: ListView(scrollDirection: Axis.horizontal, children: [
                          for (final p in (photos[phase] as List).cast<Map>())
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => afficherImage(context, '${(p['document'] as Map)['id']}'),
                                // Chantier terminé ou annulé : les photos sont des preuves, l'API refuse leur retrait
                                onLongPress: ferme ? null : () => _supprimerPhoto(context, p, recharger),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.rayon),
                                  child: SizedBox(width: 96, height: 96, child: ImageApi('${(p['document'] as Map)['id']}')),
                                ),
                              ),
                            ),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.espaceSm),
              ],
              const SizedBox(height: AppTheme.espaceSm),
              Section(titre: 'Dépenses', padding: false, children: [
                if (depenses.isEmpty) const ListTile(title: Text('Aucune dépense liée')),
                for (final d in depenses)
                  ListTile(
                    title: Text('${d['description'] ?? (d['category'] as Map?)?['name'] ?? 'Dépense'}'),
                    subtitle: Text(date(d['spent_on'] as String?)),
                    trailing: Montant(d['amount'] as num?),
                  ),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Historique', padding: false, children: [
                for (final e in ((t['events'] as List?) ?? []).cast<Map>().reversed)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(refs.libelle('statut_travaux', e['to_status'] as String?)),
                    subtitle: Text('${dateHeure(e['created_at'] as String?)}${e['comment'] != null ? ' · ${e['comment']}' : ''}'),
                  ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

/// Raccourci réutilisé par l'écran des incidents.
Future<void> ouvrirTravaux(BuildContext context, String id) => ouvrir(context, TravauxDetail(id: id));
