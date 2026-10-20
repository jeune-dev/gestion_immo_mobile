import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/depense/domain/entities/depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/ajouter_justificatif_depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/annuler_depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/get_depenses.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/widgets/formulaires_depense.dart';

/// Dépenses (§ 20).
class DepensesPage extends StatefulWidget {
  const DepensesPage({super.key});

  @override
  State<DepensesPage> createState() => _DepensesPageState();
}

class _DepensesPageState extends State<DepensesPage> {
  final _liste = GlobalKey<ListePagineeState<Depense>>();
  String _statut = 'valide';

  @override
  Widget build(BuildContext context) {
    return AvecActions(
      onReussite: () => _liste.currentState?.recharger(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Dépenses')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              if (await nouvelleDepense(context)) {
                _liste.currentState?.recharger();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Dépense'),
          ),
          body: Column(
            children: [
              Filtres(
                options: [
                  ('', 'Toutes'),
                  for (final o in refs.options('statut_depense'))
                    (o.code, o.label)
                ],
                valeur: _statut,
                onChange: (v) => setState(() => _statut = v),
              ),
              Expanded(
                child: ListePaginee<Depense>(
                  key: _liste,
                  cle: _statut,
                  vide: 'Aucune dépense',
                  iconeVide: Icons.shopping_bag_outlined,
                  charger: (page) => sl<GetDepenses>()(
                      page: page, statut: _statut.isEmpty ? null : _statut),
                  element: (context, d) => ListTile(
                    title: Text(
                        '${d.categorieNom ?? 'Dépense'} · ${d.immeubleNom ?? ''}'),
                    subtitle: Text(
                      [
                        date(d.dateDepense),
                        refs.libelle('mode_paiement', d.moyen),
                        if (d.description != null) d.description!
                      ].join(' · '),
                    ),
                    trailing: d.statut == 'annulee'
                        ? const Pastille('Annulée')
                        : Montant(d.montant,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => _detail(context, d),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _detail(BuildContext context, Depense d) async {
    final actions = context.read<ActionsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(d.categorieNom ?? 'Dépense',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Ligne('Montant', montant(d.montant)),
              Ligne('Immeuble', d.immeubleNom ?? ''),
              if (d.appartementNumero != null)
                Ligne('Appartement', d.appartementNumero),
              Ligne('Date', date(d.dateDepense)),
              Ligne('Moyen', refs.libelle('mode_paiement', d.moyen)),
              if (d.artisanNom != null) Ligne('Artisan', d.artisanNom),
              if (d.travauxTitre != null) Ligne('Travaux', d.travauxTitre),
              if (d.description != null) Ligne('Description', d.description),
              if (d.motifAnnulation != null)
                Ligne("Motif d'annulation", d.motifAnnulation),
              const SizedBox(height: AppTheme.espaceLg),
              SectionDocuments(
                  type: 'expense',
                  ajout: false,
                  id: d.id,
                  titre: 'Justificatifs'),
              if (d.valide) ...[
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
                    Navigator.pop(ctx);
                    actions.executer(
                        sl<AjouterJustificatifDepense>()(d.id, photo.path),
                        succes: 'Justificatif ajouté');
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Ajouter un justificatif'),
                ),
                TextButton(
                  onPressed: () async {
                    final motif = await confirmer(
                      ctx,
                      titre: 'Annuler la dépense',
                      message:
                          'La dépense et son mouvement de caisse seront annulés.',
                      motif: true,
                      danger: true,
                    );
                    if (motif == null || !ctx.mounted) return;
                    Navigator.pop(ctx);
                    actions.executer(sl<AnnulerDepense>()(d.id, motif),
                        succes: 'Dépense annulée');
                  },
                  child: Text('Annuler la dépense',
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
              ],
              if (d.statut == 'annulee')
                const Pastille('Dépense annulée', ton: TonStatut.neutre),
            ],
          ),
        ),
      ),
    );
  }
}
