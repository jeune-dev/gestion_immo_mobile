import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/referentiels.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/sources.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';

/// Catégories de dépenses actives (catalogue + catégories propres au propriétaire).
Future<List<OptionRef>> categoriesDepenses() async {
  final r = await api.get<Map<String, dynamic>>('/categories-depenses');
  return [for (final c in (r['categories'] as List).cast<Map>()) OptionRef('${c['id']}', '${c['name']}')];
}

/// Saisie d'une dépense (§ 20). Hors ligne, elle est mise en file et
/// synchronisée au retour du réseau (§ 34) grâce à `client_reference`.
Future<bool> nouvelleDepense(BuildContext context, {Map? travaux}) async {
  List<OptionRef> categories;
  try {
    categories = await categoriesDepenses();
  } catch (e) {
    if (context.mounted) afficherErreurApi(context, e);
    return false;
  }
  if (!context.mounted) return false;
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: travaux == null ? 'Nouvelle dépense' : 'Dépense du chantier',
      initial: {'spent_on': aujourdhui(), 'method': 'especes'},
      intro: travaux == null ? const Text('Une dépense en espèces est aussi enregistrée dans la caisse.') : Text('${travaux['title']}'),
      champs: [
        if (travaux == null) Champ('building_id', 'Immeuble', type: TypeChamp.entite, obligatoire: true, entite: Sources.immeubles),
        Champ('category_id', 'Catégorie', type: TypeChamp.selection, options: categories, obligatoire: travaux == null),
        const Champ('amount', 'Montant', type: TypeChamp.montant, obligatoire: true, min: 1),
        const Champ('method', 'Moyen de paiement', type: TypeChamp.selection, referentiel: 'mode_paiement', obligatoire: true),
        const Champ('spent_on', 'Date', type: TypeChamp.date, obligatoire: true),
        const Champ('description', 'Description', type: TypeChamp.multiligne, maxLongueur: 500),
        Champ('contractor_id', 'Artisan (facultatif)', type: TypeChamp.entite, entite: Sources.artisans),
      ],
      libelleEnvoi: 'Enregistrer',
      envoyer: (corps) async {
        corps['client_reference'] = 'dep-${nouvelleCle()}';
        if (travaux != null) {
          return api.post<Map<String, dynamic>>('/travaux/${travaux['id']}/depenses', body: corps, idempotence: nouvelleCle());
        }
        final r = await Services.fileAttente.envoyerOuDifferer<Map<String, dynamic>>(
          libelle: 'Dépense de ${montant(lireMontant('${corps['amount']}') ?? corps['amount'] as num?)}',
          chemin: '/depenses',
          corps: corps,
        );
        return r ?? 'differee';
      },
    ),
  );
  if (r == null || !context.mounted) return false;
  afficherSucces(context, r == 'differee' ? 'Hors ligne : la dépense sera envoyée au retour du réseau.' : 'Dépense enregistrée');
  return true;
}

/// Correction d'une dépense (`PATCH /depenses/:id`) : classification, appartement,
/// artisan et description. Le montant, le moyen et la date ne se modifient pas :
/// une erreur se corrige en annulant la dépense puis en la ressaisissant.
Future<bool> modifierDepense(BuildContext context, Map d) async {
  List<OptionRef> categories;
  try {
    categories = await categoriesDepenses();
  } catch (e) {
    if (context.mounted) afficherErreurApi(context, e);
    return false;
  }
  if (!context.mounted) return false;
  final categorie = d['category'] as Map?;
  final categorieId = d['category_id'] ?? categorie?['id'];
  // Catégorie désactivée depuis : elle reste proposée pour ne pas forcer un changement
  if (categorieId != null && !categories.any((o) => o.code == '$categorieId')) {
    categories = [OptionRef('$categorieId', '${categorie?['name'] ?? 'Catégorie actuelle'} (désactivée)'), ...categories];
  }
  final immeuble = '${d['building_id'] ?? (d['building'] as Map?)?['id'] ?? ''}';
  final appartement = d['apartment'] as Map?;
  final artisan = d['contractor'] as Map?;
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Modifier la dépense',
      intro: const Text('Le montant, le moyen et la date ne se modifient pas : annulez la dépense et ressaisissez-la si besoin.'),
      initial: {
        'category_id': ?categorieId,
        'description': d['description'],
        'apartment_id': d['apartment_id'] ?? appartement?['id'],
        if (appartement != null) 'apartment_id__libelle': 'Appartement ${appartement['number']}',
        'contractor_id': d['contractor_id'] ?? artisan?['id'],
        if (artisan != null) 'contractor_id__libelle': '${artisan['name']}',
      },
      champs: [
        Champ('category_id', 'Catégorie', type: TypeChamp.selection, options: categories, obligatoire: true),
        Champ('apartment_id', 'Appartement (facultatif)', type: TypeChamp.entite, nullable: true,
            entite: Sources.appartements(immeuble: immeuble.isEmpty ? null : immeuble)),
        Champ('contractor_id', 'Artisan (facultatif)', type: TypeChamp.entite, nullable: true, entite: Sources.artisans),
        const Champ('description', 'Description', type: TypeChamp.multiligne, maxLongueur: 500),
      ],
      messageSucces: 'Dépense modifiée',
      envoyer: (corps) async => (await api.patch<Map<String, dynamic>>('/depenses/${d['id']}', body: corps))['expense'],
    ),
  );
  return r != null;
}

/// Dépenses (§ 20), filtrées par période.
class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  String _statut = 'valide';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await nouvelleDepense(context)) _liste.currentState?.recharger();
        },
        icon: const Icon(Icons.add),
        label: const Text('Dépense'),
      ),
      body: Column(children: [
        Filtres(
          options: [('', 'Toutes'), for (final o in refs.options('statut_depense')) (o.code, o.label)],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _statut,
            vide: 'Aucune dépense',
            iconeVide: Icons.shopping_bag_outlined,
            charger: (page) => api.get('/depenses', query: {'page': page, 'status': _statut, 'tri': '-spent_on'}),
            element: (context, d) => ListTile(
              title: Text('${(d['category'] as Map?)?['name'] ?? 'Dépense'} · ${(d['building'] as Map?)?['name'] ?? ''}'),
              subtitle: Text([
                date(d['spent_on'] as String?),
                refs.libelle('mode_paiement', d['method'] as String?),
                if (d['description'] != null) '${d['description']}',
              ].join(' · ')),
              trailing: d['status'] == 'annulee' ? const Pastille('Annulée') : Montant(d['amount'] as num?, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _detail(d),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _detail(Map<String, dynamic> d) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${(d['category'] as Map?)?['name'] ?? 'Dépense'}', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 8),
          Ligne('Montant', montant(d['amount'] as num?)),
          Ligne('Immeuble', '${(d['building'] as Map?)?['name'] ?? ''}'),
          if (d['apartment'] != null) Ligne('Appartement', '${(d['apartment'] as Map)['number']}'),
          Ligne('Date', date(d['spent_on'] as String?)),
          Ligne('Moyen', refs.libelle('mode_paiement', d['method'] as String?)),
          if (d['contractor'] != null) Ligne('Artisan', '${(d['contractor'] as Map)['name']}'),
          if (d['workOrder'] != null) Ligne('Travaux', '${(d['workOrder'] as Map)['title']}'),
          if (d['description'] != null) Ligne('Description', '${d['description']}'),
          if (d['cancel_reason'] != null) Ligne("Motif d'annulation", '${d['cancel_reason']}'),
          const SizedBox(height: AppTheme.espaceLg),
          SectionDocuments(type: 'expense', ajout: false, id: '${d['id']}', titre: 'Justificatifs'),
          if (d['status'] == 'valide') ...[
            const SizedBox(height: AppTheme.espaceSm),
            OutlinedButton.icon(
              onPressed: () async {
                if (!await modifierDepense(ctx, d) || !ctx.mounted) return;
                Navigator.pop(ctx);
                _liste.currentState?.recharger();
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final photo = await choisirPhoto(ctx);
                if (photo == null || !ctx.mounted) return;
                await executer(ctx, () => api.upload<dynamic>('/depenses/${d['id']}/justificatifs', cheminFichier: photo.path),
                    succes: 'Justificatif ajouté');
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Ajouter un justificatif'),
            ),
            TextButton(
              onPressed: () async {
                final motif = await confirmer(ctx,
                    titre: 'Annuler la dépense', message: 'La dépense et son mouvement de caisse seront annulés.', motif: true, danger: true);
                if (motif == null || !ctx.mounted) return;
                await executer(ctx, () => api.post<dynamic>('/depenses/${d['id']}/annuler', body: {'reason': motif}), succes: 'Dépense annulée');
                if (ctx.mounted) Navigator.pop(ctx);
                _liste.currentState?.recharger();
              },
              child: Text('Annuler la dépense', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
          ],
          if (d['status'] == 'annulee') const Pastille('Dépense annulée', ton: TonStatut.neutre),
        ]),
      ),
    );
  }
}
