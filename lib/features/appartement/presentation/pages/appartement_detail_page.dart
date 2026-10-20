import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/bail/presentation/pages/bail_detail_page.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/formulaire_bail.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/pages/locataire_detail_page.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/bloc/appartement_bloc.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/bloc/appartement_event.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/bloc/appartement_state.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/formulaire_appartement.dart';

class AppartementDetailPage extends StatelessWidget {
  final String id;
  const AppartementDetailPage({super.key, required this.id});

  Future<void> _changerStatut(BuildContext context, Appartement a) async {
    final bloc = context.read<AppartementBloc>();
    final statut = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // « Occupé » ne s'obtient QUE par l'activation d'un bail (§ 8)
            for (final o in refs
                .options('statut_appartement')
                .where((o) => o.code != 'occupe'))
              ListTile(
                  title: Text(o.label),
                  selected: o.code == a.statut,
                  onTap: () => Navigator.pop(ctx, o.code)),
          ],
        ),
      ),
    );
    if (statut != null) bloc.add(ChangerStatutAppartementEvent(id, statut));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AppartementBloc>()..add(LoadAppartement(id)),
      child: BlocConsumer<AppartementBloc, AppartementState>(
        listener: (context, state) {
          if (state is AppartementSuccess) {
            afficherSucces(context, state.message);
          } else if (state is AppartementActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is AppartementSupprime) {
            afficherSucces(context, state.message);
            Navigator.of(context).pop(true);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is AppartementInitial ||
            state is AppartementLoading ||
            state is AppartementLoaded ||
            state is AppartementError,
        builder: (context, state) {
          if (state is AppartementLoaded) {
            return _buildFiche(context, state.fiche);
          }
          return VueChargement(
            titre: 'Appartement',
            failure: state is AppartementError ? state.failure : null,
            onReessayer: () =>
                context.read<AppartementBloc>().add(LoadAppartement(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, FicheAppartement fiche) {
    final bloc = context.read<AppartementBloc>();
    final a = fiche.appartement;
    final r = fiche.rentabilite;
    final bail = a.bailCourant;
    final locataire = a.locataireCourant;
    return Scaffold(
      appBar: AppBar(
        title: Text('Appartement ${a.numero}'),
        actions: [
          MenuActions(
            actions: [
              (
                'Modifier',
                () async {
                  if (await formulaireAppartement(context, existant: a) !=
                      null) {
                    bloc.add(RafraichirAppartement(id));
                  }
                },
                false,
              ),
              if (!a.occupe)
                ('Changer le statut', () => _changerStatut(context, a), false),
              (
                'Supprimer',
                () async {
                  final ok = await confirmer(
                    context,
                    titre: 'Supprimer l’appartement',
                    message:
                        'Un appartement qui a un historique (baux, paiements) ne peut pas être supprimé.',
                    action: 'Supprimer',
                    danger: true,
                  );
                  if (ok != null) bloc.add(SupprimerAppartementEvent(id));
                },
                true,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: a.occupe
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final b = await formulaireBail(
                  context,
                  initial: {
                    'apartment_id': id,
                    'apartment_id__libelle': 'Appartement ${a.numero}',
                    'rent_amount': a.loyer,
                    'charges_amount': a.charges,
                  },
                );
                if (b != null && context.mounted) {
                  await ouvrir(context, BailDetailPage(id: b.id));
                  bloc.add(RafraichirAppartement(id));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un bail'),
            ),
      body: RefreshIndicator(
        onRefresh: () async => bloc.add(RafraichirAppartement(id)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Section(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(a.immeubleNom ?? '',
                            style: Theme.of(context).textTheme.titleMedium)),
                    Statut(FamilleStatut.appartement, 'statut_appartement',
                        a.statut),
                  ],
                ),
                const SizedBox(height: AppTheme.espaceSm),
                Ligne('Type', refs.libelle('type_appartement', a.type)),
                Ligne('Étage', a.etage == null ? null : '${a.etage}'),
                Ligne('Surface', a.surface == null ? null : '${a.surface} m²'),
                Ligne('Pièces', a.nbPieces == null ? null : '${a.nbPieces}'),
                Ligne('Meublé', a.meuble ? 'Oui' : 'Non'),
                Ligne('Loyer', montant(a.loyer)),
                Ligne('Charges', montant(a.charges)),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Occupation',
              padding: false,
              children: [
                if (bail != null && locataire != null)
                  ListTile(
                    leading: CircleAvatar(child: Text(locataire.initiales)),
                    title: Text(locataire.nomComplet),
                    subtitle: Text(
                        '${bail.reference ?? ''} · depuis le ${date(bail.debut)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        ouvrir(context, BailDetailPage(id: bail.bailId)),
                  )
                else
                  const ListTile(title: Text('Aucun locataire actuellement')),
                for (final h
                    in a.historique.where((h) => h.bailId != bail?.bailId))
                  ListTile(
                    dense: true,
                    title: Text(h.locataire?.nomComplet ?? '—'),
                    subtitle: Text('${date(h.debut)} → ${date(h.fin)}'),
                    trailing:
                        Statut(FamilleStatut.bail, 'statut_bail', h.statut),
                    onTap: h.locataire == null
                        ? null
                        : () => ouvrir(
                            context, LocataireDetailPage(id: h.locataire!.id)),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Rentabilité ${bloc.annee}',
              children: [
                Ligne('Loyers encaissés', montant(r.loyersEncaisses)),
                Ligne('Charges récupérées', montant(r.chargesRecuperees)),
                Ligne('Dépenses', montant(r.depenses)),
                const Divider(),
                Ligne(
                  'Résultat net',
                  null,
                  widget: Montant(
                    r.resultatNet,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (r.resultatNet ?? 0) < 0
                          ? context.palette.danger
                          : context.palette.succes,
                    ),
                  ),
                ),
                Ligne('Impayés', montant(r.impayes)),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            // Historique de l'appartement (§ 25) : baux, paiements, travaux, dépenses, incidents.
            Section(
              titre: 'Historique',
              padding: false,
              children: [
                if (fiche.historique.isEmpty)
                  const ListTile(title: Text('Aucun événement')),
                for (final e in fiche.historique)
                  ListTile(
                    dense: true,
                    title: Text(e.libelle),
                    subtitle: Text(date(e.date)),
                    trailing: e.montant == null ? null : Montant(e.montant),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            SectionDocuments(type: 'apartment', id: id),
          ],
        ),
      ),
    );
  }
}
