import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/abonnement/domain/entities/abonnement.dart';
import 'package:gestion_immo_mobile/features/abonnement/presentation/bloc/abonnement_bloc.dart';
import 'package:gestion_immo_mobile/features/abonnement/presentation/bloc/abonnement_event.dart';
import 'package:gestion_immo_mobile/features/abonnement/presentation/bloc/abonnement_state.dart';

/// Abonnement SaaS (§ 31) : plan en cours, consommation, renouvellement par PayDunya.
/// Consultable même abonnement échu : c'est le moyen d'en sortir.
class AbonnementPage extends StatelessWidget {
  const AbonnementPage({super.key});

  Future<void> _souscrire(BuildContext context, PlanAbonnement plan) async {
    final bloc = context.read<AbonnementBloc>();
    var mois = 1;
    String? portefeuille;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Plan ${plan.nom}',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Durée', style: Theme.of(ctx).textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in [1, 3, 6, 12])
                      ChoiceChip(
                          label: Text('$m mois'),
                          selected: mois == m,
                          onSelected: (_) => setState(() => mois = m)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Payer avec', style: Theme.of(ctx).textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                        label: const Text('Au choix'),
                        selected: portefeuille == null,
                        onSelected: (_) => setState(() => portefeuille = null)),
                    for (final o in refs.options('portefeuille'))
                      ChoiceChip(
                          label: Text(o.label),
                          selected: portefeuille == o.code,
                          onSelected: (_) =>
                              setState(() => portefeuille = o.code)),
                  ],
                ),
                const SizedBox(height: 16),
                Ligne('Total', montant(plan.prix * mois)),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Payer')),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      bloc.add(SouscrireAbonnementEvent(plan.code, mois, portefeuille));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AbonnementBloc>()..add(LoadAbonnement()),
      child: BlocConsumer<AbonnementBloc, AbonnementState>(
        listener: (context, state) {
          if (state is AbonnementSuccess) {
            afficherSucces(context, state.message);
          } else if (state is AbonnementActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is LienPaiementAbonnementLoaded) {
            _ouvrirPaiement(context, state);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is AbonnementInitial ||
            state is AbonnementLoading ||
            state is AbonnementLoaded ||
            state is AbonnementError,
        builder: (context, state) {
          if (state is AbonnementLoaded) {
            return _buildFiche(context, state.fiche);
          }
          return VueChargement(
            titre: 'Abonnement',
            failure: state is AbonnementError ? state.failure : null,
            onReessayer: () =>
                context.read<AbonnementBloc>().add(LoadAbonnement()),
          );
        },
      ),
    );
  }

  Future<void> _ouvrirPaiement(
      BuildContext context, LienPaiementAbonnementLoaded state) async {
    await launchUrl(Uri.parse(state.url), mode: LaunchMode.externalApplication);
    if (context.mounted) {
      afficherSucces(context,
          'Après le paiement, revenez ici : votre abonnement sera mis à jour automatiquement.');
      // Le compte en session est relu : la bannière « lecture seule » suit le nouveau statut
      context.read<AuthBloc>().add(CompteRechargeDemande());
    }
  }

  Widget _buildFiche(BuildContext context, FicheAbonnement fiche) {
    final bloc = context.read<AbonnementBloc>();
    final a = fiche.etat;

    Widget jauge(String libelle, Quota? u) {
      if (u == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '$libelle : ${u.utilise}${u.max == null ? ' (illimité)' : ' / ${u.max}'}'),
            if (u.max != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                    value: (u.utilise / u.max!).clamp(0, 1).toDouble(),
                    minHeight: 6),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon abonnement')),
      body: RefreshIndicator(
        onRefresh: () async => bloc.add(RafraichirAbonnement()),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!a.actif) ...[
              const Encadre(
                'Abonnement échu ou suspendu : votre espace est en lecture seule. Choisissez un plan pour le réactiver.',
                ton: TonStatut.danger,
              ),
              const SizedBox(height: 16),
            ],
            Section(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Plan ${a.planNom ?? '—'}',
                            style: Theme.of(context).textTheme.titleLarge)),
                    Statut(FamilleStatut.abonnement, 'statut_abonnement',
                        a.statut),
                  ],
                ),
                const SizedBox(height: 8),
                Ligne(
                    a.statut == 'essai' ? "Fin de l'essai" : 'Valable jusqu’au',
                    date(a.finPeriode)),
                const SizedBox(height: 12),
                jauge('Immeubles', a.immeubles),
                jauge('Appartements', a.appartements),
                jauge('Messages WhatsApp ce mois', a.whatsappCeMois),
              ],
            ),
            const SizedBox(height: 16),
            Text('Choisir un plan',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in fiche.plans)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(p.nom,
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          if (p.code == a.planCode)
                            const Pastille('Plan actuel', ton: TonStatut.info),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${montant(p.prix)} / ${refs.libelle('periode_facturation', p.periodeFacturation).toLowerCase()}',
                        style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)
                            .merge(chiffresFixes),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          p.maxImmeubles == null
                              ? 'Immeubles illimités'
                              : '${p.maxImmeubles} immeuble(s)',
                          p.maxAppartements == null
                              ? 'appartements illimités'
                              : '${p.maxAppartements} appartements',
                        ].join(' · '),
                      ),
                      if (p.fonctionnalites.isNotEmpty)
                        Text(
                          p.fonctionnalites
                              .map((f) => refs.libelle('fonctionnalite', f))
                              .join(' · '),
                          style:
                              TextStyle(color: context.palette.texteSecondaire),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              p.prix == 0 ? null : () => _souscrire(context, p),
                          child: Text(p.code == a.planCode
                              ? 'Renouveler'
                              : 'Choisir ce plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Paiements',
              padding: false,
              children: [
                if (fiche.paiements.isEmpty)
                  const ListTile(title: Text('Aucun paiement')),
                for (final p in fiche.paiements)
                  ListTile(
                    title: Text('${p.planNom ?? ''} · ${p.mois} mois'),
                    subtitle:
                        Text('${p.reference ?? ''} · ${dateHeure(p.date)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Montant(p.montant),
                        Text(
                            refs.libelle(
                                'statut_paiement_abonnement', p.statut),
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onTap: p.statut == 'initie' && p.checkoutUrl != null
                        ? () => launchUrl(Uri.parse(p.checkoutUrl!),
                            mode: LaunchMode.externalApplication)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
