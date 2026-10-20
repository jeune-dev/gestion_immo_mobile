import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeances_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/factures_communes_page.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incidents_page.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/bouton_notifications.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/rapprochements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/transactions_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';
import 'package:gestion_immo_mobile/features/dashboard/domain/entities/tableau_de_bord.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';

/// Tableau de bord « immédiatement compréhensible » (cahier des charges § 6, § 48).
class DashboardPage extends StatelessWidget {
  /// Change d'onglet (0 Accueil, 1 Biens, 2 Finances, 3 Travaux, 4 Profil).
  final ValueChanged<int> onAller;
  const DashboardPage({super.key, required this.onAller});

  void _ouvrir(BuildContext context, Widget ecran) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));

  @override
  Widget build(BuildContext context) {
    final prenom = context
        .select((AuthBloc b) => b.state.compte?.utilisateur.prenom ?? '');
    final lectureSeule = context.select((AuthBloc b) => b.state.lectureSeule);
    return BlocProvider(
      create: (_) => di.sl<DashboardBloc>()..add(LoadDashboard()),
      // Builder : le bouton d'encaissement relit le tableau de bord via le Bloc fourni ci-dessus
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Bonjour $prenom'),
            actions: [
              IconButton(
                  tooltip: 'Notifications',
                  icon: const BoutonNotifications(),
                  onPressed: () => _ouvrir(context, const NotificationsPage())),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              if (await encaisser(context) && context.mounted) {
                context.read<DashboardBloc>().add(RafraichirDashboard());
              }
            },
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Encaisser un loyer'),
          ),
          body: BlocBuilder<DashboardBloc, DashboardState>(
            // Un échec de rafraîchissement laisse le tableau de bord affiché.
            buildWhen: (_, state) => state is! DashboardActionError,
            builder: (context, state) {
              if (state is! DashboardLoaded) {
                return VueChargement(
                  failure: state is DashboardError ? state.failure : null,
                  onReessayer: () =>
                      context.read<DashboardBloc>().add(LoadDashboard()),
                );
              }
              final d = state.tableauDeBord;
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<DashboardBloc>().add(RafraichirDashboard()),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppTheme.espaceLg,
                      AppTheme.espaceLg, AppTheme.espaceLg, 96),
                  children: [
                    if (lectureSeule) ...[
                      Encadre(
                        'Votre abonnement est échu : vos données restent consultables mais ne peuvent plus être modifiées.',
                        ton: TonStatut.danger,
                        action: TextButton(
                            onPressed: () => context.push(AppRouter.abonnement),
                            child: const Text('Renouveler')),
                      ),
                      const SizedBox(height: AppTheme.espaceLg),
                    ],
                    _Titre('Mon patrimoine · ${mois(d.mois)}'),
                    Section(
                      children: [
                        Wrap(
                          spacing: AppTheme.espaceXl,
                          runSpacing: AppTheme.espaceSm,
                          children: [
                            _Compteur('${d.immeubles}', 'immeubles'),
                            _Compteur('${d.appartements}', 'appartements'),
                            _Compteur('${d.occupes}', 'occupés'),
                            _Compteur('${d.disponibles}', 'disponibles'),
                          ],
                        ),
                        const SizedBox(height: AppTheme.espaceMd),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                              value: (d.tauxOccupation ?? 0) / 100,
                              minHeight: 8),
                        ),
                        const SizedBox(height: AppTheme.espaceXs),
                        Text(
                          "Taux d'occupation ${pourcent(d.tauxOccupation)}",
                          style: TextStyle(
                              color: context.palette.texteSecondaire,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.espaceLg),
                    _Titre('Loyers du mois'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppTheme.espaceSm,
                      crossAxisSpacing: AppTheme.espaceSm,
                      childAspectRatio: 1.35,
                      children: [
                        ChiffreCle(
                            libelle: 'À recevoir',
                            valeur: montant(d.aRecevoir),
                            icone: Icons.schedule,
                            ton: TonStatut.info),
                        ChiffreCle(
                            libelle: 'Encaissés',
                            valeur: montant(d.encaisses),
                            icone: Icons.check_circle_outline,
                            ton: TonStatut.succes),
                        ChiffreCle(
                          libelle: 'Impayés',
                          valeur: montant(d.impayes),
                          icone: Icons.error_outline,
                          ton: TonStatut.danger,
                          onTap: () => _ouvrir(
                              context, const EcheancesPage(impayes: true)),
                        ),
                        ChiffreCle(
                          libelle: 'Dépenses',
                          valeur: montant(d.depenses),
                          icone: Icons.receipt_long_outlined,
                          ton: TonStatut.neutre,
                          sous: 'Résultat ${montant(d.resultat)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.espaceLg),
                    _ATraiter(
                        d: d,
                        ouvrir: (w) => _ouvrir(context, w),
                        onTravaux: () => onAller(3)),
                    const SizedBox(height: AppTheme.espaceLg),
                    if (d.totalDebiteurs > 0) ...[
                      _Titre("Qui n'a pas payé ? · ${d.totalDebiteurs}"),
                      Section(
                        padding: false,
                        children: [
                          for (final x in d.debiteurs.take(5))
                            ListTile(
                              leading: CircleAvatar(
                                  child: Text(x.locataire.initiales)),
                              title: Text(x.locataire.nomComplet),
                              subtitle: Text(
                                  '${x.immeuble ?? ''} · ${x.appartement ?? ''} · depuis le ${date(x.depuis)}'),
                              trailing: Montant(
                                x.montant,
                                style: TextStyle(
                                    color: context.palette.danger,
                                    fontWeight: FontWeight.w600),
                              ),
                              onTap: () => _ouvrir(
                                  context,
                                  EcheancesPage(
                                      impayes: true,
                                      locataireId: x.locataire.id,
                                      titre: x.locataire.nomComplet)),
                            ),
                          TextButton(
                            onPressed: () => _ouvrir(
                                context, const EcheancesPage(impayes: true)),
                            child: const Text('Voir tous les impayés'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.espaceLg),
                    ],
                    _Titre('Revenus et dépenses · 6 mois'),
                    Section(children: [_GraphiqueRevenus(d)]),
                    const SizedBox(height: AppTheme.espaceLg),
                    if (d.depensesParCategorie.isNotEmpty) ...[
                      _Titre('Dépenses par catégorie'),
                      Section(children: [
                        for (final c in d.depensesParCategorie)
                          Ligne(c.nom, montant(c.total))
                      ]),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.espaceSm, left: 2),
        child: Text(
          texte.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: context.palette.texteSecondaire),
        ),
      );
}

class _Compteur extends StatelessWidget {
  final String valeur;
  final String libelle;
  const _Compteur(this.valeur, this.libelle);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valeur,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)
                  .merge(chiffresFixes)),
          Text(libelle,
              style: TextStyle(color: context.palette.texteSecondaire)),
        ],
      );
}

class _ATraiter extends StatelessWidget {
  final TableauDeBord d;
  final void Function(Widget) ouvrir;
  final VoidCallback onTravaux;
  const _ATraiter(
      {required this.d, required this.ouvrir, required this.onTravaux});

  @override
  Widget build(BuildContext context) {
    final lignes = <(IconData, String, int, VoidCallback)>[
      (
        Icons.fact_check_outlined,
        'Preuves de paiement à valider',
        d.preuvesAValider,
        () => ouvrir(const TransactionsPage(aValider: true))
      ),
      (
        Icons.compare_arrows,
        'Paiements à rapprocher',
        d.aRapprocher,
        () => ouvrir(const RapprochementsPage())
      ),
      (
        Icons.water_drop_outlined,
        'Factures communes à répartir',
        d.facturesARepartir,
        () => ouvrir(const FacturesCommunesPage(statut: 'brouillon'))
      ),
      (
        Icons.report_problem_outlined,
        'Incidents ouverts',
        d.incidentsOuverts,
        () => ouvrir(const IncidentsPage(ouverts: true))
      ),
      (
        Icons.handyman_outlined,
        'Travaux en cours',
        d.travauxEnCours,
        onTravaux
      ),
    ].where((l) => l.$3 > 0).toList();
    if (lignes.isEmpty) return const SizedBox.shrink();
    return Section(
      titre: 'À traiter',
      padding: false,
      children: [
        for (final (icone, libelle, n, onTap) in lignes)
          ListTile(
            leading: Icon(icone, color: context.palette.avertissement),
            title: Text(libelle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pastille('$n', ton: TonStatut.avertissement),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: onTap,
          ),
      ],
    );
  }
}

/// Revenus (bleu) et dépenses (neutre) des derniers mois.
class _GraphiqueRevenus extends StatelessWidget {
  final TableauDeBord d;
  const _GraphiqueRevenus(this.d);

  @override
  Widget build(BuildContext context) {
    final revenus = d.revenusMensuels;
    final depenses = d.depensesMensuelles;
    final max = [...revenus.map((r) => r.total), ...depenses.values, 1]
        .reduce((a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;
    final p = context.palette;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: max * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                        moisCourt(revenus[v.toInt()].mois),
                        style:
                            TextStyle(fontSize: 11, color: p.texteSecondaire)),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => cs.inverseSurface,
                  getTooltipItem: (groupe, _, barre, i) => BarTooltipItem(
                      montant(barre.toY),
                      TextStyle(color: cs.onInverseSurface, fontSize: 12)),
                ),
              ),
              barGroups: [
                for (var i = 0; i < revenus.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                          toY: revenus[i].total.toDouble(),
                          color: cs.primary,
                          width: 10,
                          borderRadius: BorderRadius.circular(3)),
                      BarChartRodData(
                        toY: (depenses[revenus[i].mois] ?? 0).toDouble(),
                        color: p.bordureForte,
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.espaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legende(cs.primary, 'Revenus'),
            const SizedBox(width: AppTheme.espaceLg),
            _Legende(p.bordureForte, 'Dépenses'),
          ],
        ),
      ],
    );
  }
}

class _Legende extends StatelessWidget {
  final Color couleur;
  final String libelle;
  const _Legende(this.couleur, this.libelle);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: couleur, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          Text(libelle,
              style: TextStyle(
                  fontSize: 12, color: context.palette.texteSecondaire)),
        ],
      );
}
