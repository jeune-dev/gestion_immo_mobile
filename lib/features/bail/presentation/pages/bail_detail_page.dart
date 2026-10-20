import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
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
import 'package:gestion_immo_mobile/features/caution/presentation/pages/caution_detail_page.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeances_page.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/pages/comparaison_page.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/pages/etat_des_lieux_detail_page.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/widgets/creer_etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/pages/locataire_detail_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/bloc/bail_bloc.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/bloc/bail_event.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/bloc/bail_state.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/formulaire_bail.dart';

/// Contrat de location (§ 10) et son cycle : brouillon → actif → terminé → clos.
class BailDetailPage extends StatelessWidget {
  final String id;
  const BailDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<BailBloc>()..add(LoadBail(id)),
      child: BlocConsumer<BailBloc, BailState>(
        listener: (context, state) {
          if (state is BailSuccess) {
            afficherSucces(context, state.message);
          } else if (state is BailActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is AvertissementsActivationLoaded) {
            _afficherAvertissements(context, state);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is BailInitial ||
            state is BailLoading ||
            state is BailLoaded ||
            state is BailError,
        builder: (context, state) {
          if (state is BailLoaded) {
            return _buildFiche(context, state.fiche);
          }
          return VueChargement(
            titre: 'Bail',
            failure: state is BailError ? state.failure : null,
            onReessayer: () => context.read<BailBloc>().add(LoadBail(id)),
          );
        },
      ),
    );
  }

  void _afficherAvertissements(
      BuildContext context, AvertissementsActivationLoaded state) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('À noter'),
        content: Text(state.messages.map((m) => '• $m').join('\n')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }

  Widget _buildFiche(BuildContext context, FicheBail fiche) {
    final bloc = context.read<BailBloc>();
    return _Fiche(
      fiche: fiche,
      recharger: () => bloc.add(RafraichirBail(id)),
    );
  }
}

class _Fiche extends StatelessWidget {
  final FicheBail fiche;
  final VoidCallback recharger;
  const _Fiche({required this.fiche, required this.recharger});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BailBloc>();
    final b = fiche.bail;
    final statut = b.statut;
    final caution = b.caution;

    final actions = <(String, VoidCallback, bool)>[
      if (statut == 'brouillon')
        (
          'Modifier',
          () async {
            if (await formulaireBail(context, existant: b) != null) recharger();
          },
          false,
        ),
      if (statut == 'actif')
        (
          'Réviser le loyer',
          () async {
            if (await reviserLoyer(context, b)) recharger();
          },
          false,
        ),
      if (statut == 'actif')
        (
          'Mettre fin au bail',
          () async {
            if (await terminerBail(context, b)) recharger();
          },
          true,
        ),
      if (statut == 'termine')
        (
          'Clôturer le bail',
          () async {
            final ok = await confirmer(
              context,
              titre: 'Clôturer le bail',
              message:
                  'Possible seulement quand la caution est restituée ou que le litige est documenté.',
              action: 'Clôturer',
            );
            if (ok != null) bloc.add(CloturerBailEvent(fiche.bail.id));
          },
          false,
        ),
      if (statut == 'brouillon')
        (
          'Annuler le bail',
          () async {
            final motif = await confirmer(
              context,
              titre: 'Annuler le bail',
              message: 'Le brouillon sera annulé.',
              action: 'Annuler le bail',
              danger: true,
              motif: true,
            );
            if (motif != null) bloc.add(AnnulerBailEvent(fiche.bail.id, motif));
          },
          true,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(b.reference ?? 'Bail'),
        actions: [MenuActions(actions: actions)],
      ),
      floatingActionButton: statut == 'brouillon'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await confirmer(
                  context,
                  titre: 'Activer le bail',
                  message:
                      "L'appartement passe « Occupé », les échéances sont générées sur 12 mois et la caution est ouverte.",
                  action: 'Activer',
                );
                if (ok != null) bloc.add(ActiverBailEvent(fiche.bail.id));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Activer le bail'),
            )
          : statut == 'actif'
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    if (await encaisser(context, bail: b)) recharger();
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Encaisser'),
                )
              : null,
      body: RefreshIndicator(
        onRefresh: () async => recharger(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Section(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(refs.libelle('type_bail', b.typeBail),
                            style: Theme.of(context).textTheme.titleMedium)),
                    Statut(FamilleStatut.bail, 'statut_bail', statut),
                  ],
                ),
                const SizedBox(height: AppTheme.espaceSm),
                Ligne(
                  'Locataire',
                  null,
                  widget: TextButton(
                    onPressed: b.locataire == null
                        ? null
                        : () => ouvrir(
                            context, LocataireDetailPage(id: b.locataire!.id)),
                    child: Text(nomDe(b.locataire)),
                  ),
                ),
                Ligne('Logement',
                    'Appartement ${b.logement?.numero ?? ''} · ${b.logement?.immeubleNom ?? ''}'),
                Ligne('Période',
                    '${date(b.debut)} → ${b.fin == null ? 'durée indéterminée' : date(b.fin)}'),
                if (b.sortieLe != null) Ligne('Sorti le', date(b.sortieLe)),
                Ligne('Loyer',
                    '${montant(b.loyer)} · ${refs.libelle('periodicite', b.periodicite)}'),
                Ligne('Charges', montant(b.charges)),
                Ligne("Jour d'échéance", 'le ${b.jourEcheance ?? '—'}'),
                Ligne('Préavis', '${b.preavisMois ?? '—'} mois'),
                if (b.conditionsParticulieres != null)
                  Ligne('Conditions particulières', b.conditionsParticulieres),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            if (statut != 'brouillon')
              Section(
                titre: 'Loyers',
                action: TextButton(
                  onPressed: () => ouvrir(
                      context, EcheancesPage(bailId: b.id, titre: b.reference)),
                  child: const Text('Échéances'),
                ),
                children: [
                  Ligne(
                    'Reste dû',
                    null,
                    widget: Montant(
                      b.resteDu,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (b.resteDu ?? 0) > 0
                              ? context.palette.danger
                              : null),
                    ),
                  ),
                  Ligne('Total encaissé', montant(b.totalEncaisse)),
                ],
              ),
            if (caution != null) ...[
              const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: 'Caution',
                padding: false,
                children: [
                  ListTile(
                    title: Text(
                        '${montant(caution.recue)} reçus sur ${montant(caution.attendue)}'),
                    subtitle: (caution.retenue ?? 0) +
                                (caution.restituee ?? 0) >
                            0
                        ? Text(
                            'Retenu ${montant(caution.retenue)} · restitué ${montant(caution.restituee)}')
                        : null,
                    trailing: Statut(FamilleStatut.caution, 'statut_caution',
                        caution.statut),
                    onTap: () async {
                      await ouvrir(context, CautionDetailPage(id: caution.id));
                      recharger();
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'États des lieux',
              padding: false,
              action: statut == 'annule' || statut == 'clos'
                  ? null
                  : TextButton(
                      onPressed: () async {
                        final type = statut == 'brouillon'
                            ? 'entree'
                            : statut == 'termine'
                                ? 'sortie'
                                : null;
                        if (await creerEtatDesLieux(context,
                                bailId: b.id, type: type) !=
                            null) {
                          recharger();
                        }
                      },
                      child: const Text('Nouveau'),
                    ),
              children: [
                if (b.etatsDesLieux.isEmpty)
                  const ListTile(title: Text('Aucun état des lieux')),
                for (final i in b.etatsDesLieux)
                  ListTile(
                    title: Text(
                        '${refs.libelle('type_etat_des_lieux', i.type)} · version ${i.version ?? ''}'),
                    subtitle: Text(date(i.date)),
                    trailing: Statut(FamilleStatut.etatDesLieux,
                        'statut_etat_des_lieux', i.statut),
                    onTap: () async {
                      await ouvrir(context, EtatDesLieuxDetailPage(id: i.id));
                      recharger();
                    },
                  ),
                if (b.etatsDesLieux.any((i) => i.type == 'sortie'))
                  TextButton(
                    onPressed: () =>
                        ouvrir(context, ComparaisonPage(bailId: b.id)),
                    child: const Text('Comparer entrée et sortie'),
                  ),
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
                        if (await genererContrat(context, b)) recharger();
                      },
                      child: const Text('Générer'),
                    ),
              children: [
                if (fiche.contrats.isEmpty)
                  const ListTile(title: Text('Aucun contrat généré')),
                for (final c in fiche.contrats)
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Contrat version ${c.version}'),
                    subtitle: Text(
                        'Modèle v${c.versionModele ?? ''} · ${date(c.creeLe)}'),
                    trailing: IconButton(
                      tooltip: 'Partager',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => ouvrirFichierDocument(
                          context,
                          c.documentId,
                          'contrat-${b.reference}-v${c.version}.pdf',
                          partager: true),
                    ),
                    onTap: () => ouvrirFichierDocument(context, c.documentId,
                        'contrat-${b.reference}-v${c.version}.pdf'),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            SectionDocuments(type: 'lease', id: b.id),
            if (statut == 'termine') ...[
              const SizedBox(height: AppTheme.espaceLg),
              const Encadre(
                'Bail terminé : réglez la caution (restitution ou retenue justifiée) puis clôturez le bail depuis le menu.',
                ton: TonStatut.avertissement,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
