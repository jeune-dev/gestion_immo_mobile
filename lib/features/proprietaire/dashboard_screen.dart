import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_cubit.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../commun/notifications_screen.dart';
import 'finances/echeances_screen.dart';
import 'finances/encaissement.dart';
import 'finances/factures_screen.dart';
import 'finances/transactions_screen.dart';
import 'travaux/incidents_screen.dart';

/// Tableau de bord « immédiatement compréhensible » (cahier des charges § 6, § 48).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onAller});

  /// Change d'onglet (0 Accueil, 1 Biens, 2 Finances, 3 Travaux, 4 Profil).
  final ValueChanged<int> onAller;

  void _ouvrir(BuildContext context, Widget ecran) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final prenom = session.user?['first_name'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour $prenom'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const BoutonNotifications(),
            onPressed: () => _ouvrir(context, const NotificationsScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => encaisser(context),
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Encaisser un loyer'),
      ),
      body: Chargeur<List<dynamic>>(
        charger: () => Future.wait([
          api.get<Map<String, dynamic>>('/dashboard'),
          api.get<Map<String, dynamic>>('/dashboard/graphiques', query: {'nb_mois': 6}),
        ]),
        builder: (context, data, recharger) {
          final d = (data[0] as Map)['dashboard'] as Map;
          final g = (data[1] as Map)['graphiques'] as Map;
          final p = d['patrimoine'] as Map;
          final l = d['loyers'] as Map;
          final t = d['a_traiter'] as Map;
          final debiteurs = d['qui_n_a_pas_paye'] as Map;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppTheme.espaceLg, AppTheme.espaceLg, AppTheme.espaceLg, 96),
            children: [
              if (session.lectureSeule) ...[
                Encadre(
                  'Votre abonnement est échu : vos données restent consultables mais ne peuvent plus être modifiées.',
                  ton: TonStatut.danger,
                  action: TextButton(onPressed: () => context.push('/p/abonnement'), child: const Text('Renouveler')),
                ),
                const SizedBox(height: AppTheme.espaceLg),
              ],
              _Titre('Mon patrimoine · ${mois(d['mois'] as String)}'),
              Section(children: [
                Wrap(spacing: AppTheme.espaceXl, runSpacing: AppTheme.espaceSm, children: [
                  _Compteur('${p['immeubles']}', 'immeubles'),
                  _Compteur('${p['appartements']}', 'appartements'),
                  _Compteur('${p['occupes']}', 'occupés'),
                  _Compteur('${p['disponibles']}', 'disponibles'),
                ]),
                const SizedBox(height: AppTheme.espaceMd),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: entier(p['taux_occupation']) / 100, minHeight: 8),
                ),
                const SizedBox(height: AppTheme.espaceXs),
                Text("Taux d'occupation ${pourcent(p['taux_occupation'] as num?)}",
                    style: TextStyle(color: context.palette.texteSecondaire, fontSize: 13)),
              ]),
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
                  ChiffreCle(libelle: 'À recevoir', valeur: montant(l['a_recevoir'] as num?), icone: Icons.schedule, ton: TonStatut.info),
                  ChiffreCle(libelle: 'Encaissés', valeur: montant(l['encaisses'] as num?), icone: Icons.check_circle_outline, ton: TonStatut.succes),
                  ChiffreCle(
                    libelle: 'Impayés',
                    valeur: montant(l['impayes'] as num?),
                    icone: Icons.error_outline,
                    ton: TonStatut.danger,
                    onTap: () => _ouvrir(context, const EcheancesScreen(impayes: true)),
                  ),
                  ChiffreCle(
                    libelle: 'Dépenses',
                    valeur: montant(d['depenses'] as num?),
                    icone: Icons.receipt_long_outlined,
                    ton: TonStatut.neutre,
                    sous: 'Résultat ${montant(d['resultat'] as num?)}',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.espaceLg),
              _ATraiter(t: t, ouvrir: (w) => _ouvrir(context, w), travaux: entier(d['travaux_en_cours']), onTravaux: () => onAller(3)),
              const SizedBox(height: AppTheme.espaceLg),
              if (entier(debiteurs['total_debiteurs']) > 0) ...[
                _Titre("Qui n'a pas payé ? · ${debiteurs['total_debiteurs']}"),
                Section(padding: false, children: [
                  for (final x in (debiteurs['locataires'] as List).take(5).cast<Map>())
                    ListTile(
                      leading: CircleAvatar(child: Text(initiales(x))),
                      title: Text(nomComplet(x)),
                      subtitle: Text('${x['building_name']} · ${x['apartment_number']} · depuis le ${date(x['plus_ancienne_echeance'] as String?)}'),
                      trailing: Montant(x['montant'] as num?, style: TextStyle(color: context.palette.danger, fontWeight: FontWeight.w600)),
                      onTap: () => _ouvrir(context, EcheancesScreen(impayes: true, locataireId: '${x['tenant_id']}', titre: nomComplet(x))),
                    ),
                  TextButton(onPressed: () => _ouvrir(context, const EcheancesScreen(impayes: true)), child: const Text('Voir tous les impayés')),
                ]),
                const SizedBox(height: AppTheme.espaceLg),
              ],
              _Titre('Revenus et dépenses · 6 mois'),
              Section(children: [_GraphiqueRevenus(g)]),
              const SizedBox(height: AppTheme.espaceLg),
              if ((g['depenses_par_categorie'] as List).isNotEmpty) ...[
                _Titre('Dépenses par catégorie'),
                Section(children: [
                  for (final c in (g['depenses_par_categorie'] as List).cast<Map>())
                    Ligne('${c['name']}', montant(c['total'] as num?)),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.espaceSm, left: 2),
        child: Text(texte.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: context.palette.texteSecondaire)),
      );
}

class _Compteur extends StatelessWidget {
  const _Compteur(this.valeur, this.libelle);
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(valeur, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600).merge(chiffresFixes)),
        Text(libelle, style: TextStyle(color: context.palette.texteSecondaire)),
      ]);
}

class _ATraiter extends StatelessWidget {
  const _ATraiter({required this.t, required this.ouvrir, required this.travaux, required this.onTravaux});
  final Map t;
  final void Function(Widget) ouvrir;
  final int travaux;
  final VoidCallback onTravaux;

  @override
  Widget build(BuildContext context) {
    final lignes = <(IconData, String, int, VoidCallback)>[
      (Icons.fact_check_outlined, 'Preuves de paiement à valider', entier(t['preuves_a_valider']), () => ouvrir(const TransactionsScreen(aValider: true))),
      (Icons.compare_arrows, 'Paiements à rapprocher', entier(t['a_rapprocher']), () => ouvrir(const RapprochementsScreen())),
      (Icons.water_drop_outlined, 'Factures communes à répartir', entier(t['factures_a_repartir']), () => ouvrir(const FacturesScreen(statut: 'brouillon'))),
      (Icons.report_problem_outlined, 'Incidents ouverts', entier(t['incidents_ouverts']), () => ouvrir(const IncidentsScreen(ouverts: true))),
      (Icons.handyman_outlined, 'Travaux en cours', travaux, onTravaux),
    ].where((l) => l.$3 > 0).toList();
    if (lignes.isEmpty) return const SizedBox.shrink();
    return Section(titre: 'À traiter', padding: false, children: [
      for (final (icone, libelle, n, onTap) in lignes)
        ListTile(
          leading: Icon(icone, color: context.palette.avertissement),
          title: Text(libelle),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Pastille('$n', ton: TonStatut.avertissement),
            const Icon(Icons.chevron_right),
          ]),
          onTap: onTap,
        ),
    ]);
  }
}

/// Revenus (bleu) et dépenses (neutre) des derniers mois.
class _GraphiqueRevenus extends StatelessWidget {
  const _GraphiqueRevenus(this.g);
  final Map g;

  @override
  Widget build(BuildContext context) {
    final revenus = (g['revenus_mensuels'] as List).cast<Map>();
    final depenses = {for (final x in (g['depenses_mensuelles'] as List).cast<Map>()) x['mois']: entier(x['total'])};
    final max = [
      ...revenus.map((r) => entier(r['total'])),
      ...depenses.values,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;
    final p = context.palette;
    return Column(children: [
      SizedBox(
        height: 180,
        child: BarChart(BarChartData(
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
                getTitlesWidget: (v, _) => Text(moisCourt('${revenus[v.toInt()]['mois']}'),
                    style: TextStyle(fontSize: 11, color: p.texteSecondaire)),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItem: (groupe, _, barre, i) =>
                  BarTooltipItem(montant(barre.toY), TextStyle(color: cs.onInverseSurface, fontSize: 12)),
            ),
          ),
          barGroups: [
            for (var i = 0; i < revenus.length; i++)
              BarChartGroupData(x: i, barsSpace: 3, barRods: [
                BarChartRodData(toY: entier(revenus[i]['total']).toDouble(), color: cs.primary, width: 10, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(
                    toY: (depenses[revenus[i]['mois']] ?? 0).toDouble(), color: p.bordureForte, width: 10, borderRadius: BorderRadius.circular(3)),
              ]),
          ],
        )),
      ),
      const SizedBox(height: AppTheme.espaceSm),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _Legende(cs.primary, 'Revenus'),
        const SizedBox(width: AppTheme.espaceLg),
        _Legende(p.bordureForte, 'Dépenses'),
      ]),
    ]);
  }
}

class _Legende extends StatelessWidget {
  const _Legende(this.couleur, this.libelle);
  final Color couleur;
  final String libelle;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(libelle, style: TextStyle(fontSize: 12, color: context.palette.texteSecondaire)),
      ]);
}
