import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeances_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/factures_communes_page.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incidents_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/avatar_utilisateur.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/bouton_notifications.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/rapprochements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/transactions_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';
import 'package:gestion_immo_mobile/features/dashboard/domain/entities/tableau_de_bord.dart';
import 'package:gestion_immo_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:gestion_immo_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Tableau de bord « immédiatement compréhensible » (cahier des charges § 6, § 48).
class DashboardPage extends StatelessWidget {
  /// Change d'onglet (0 Accueil, 1 Biens, 2 Finances, 3 Travaux, 4 Profil).
  final ValueChanged<int> onAller;

  /// Change à chaque retour sur l'onglet : les chiffres sont relus.
  final Listenable? actualisation;
  const DashboardPage({super.key, required this.onAller, this.actualisation});

  void _ouvrir(BuildContext context, Widget ecran) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));

  @override
  Widget build(BuildContext context) {
    final lectureSeule = context.select((AuthBloc b) => b.state.lectureSeule);
    return BlocProvider(
      create: (_) => di.sl<DashboardBloc>()..add(LoadDashboard()),
      // Builder : le bouton d'encaissement relit le tableau de bord via le Bloc fourni ci-dessus
      child: Builder(
        builder: (context) => _Actualisation(
          signal: actualisation,
          child: Scaffold(
            // Barre vide : garde la zone de la barre d'état bleue pendant le défilement.
            appBar: AppBar(flexibleSpace: const FondMarque(), toolbarHeight: 0),
            floatingActionButton: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final fab = theme.floatingActionButtonTheme;
                return Theme(
                  data: theme.copyWith(
                    floatingActionButtonTheme: fab.copyWith(
                      extendedSizeConstraints: const BoxConstraints.tightFor(
                        height: 44,
                      ),
                      extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      extendedIconLabelSpacing: 6,
                      extendedTextStyle: fab.extendedTextStyle?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  child: FloatingActionButton.extended(
                    tooltip: 'Encaisser un loyer',
                    onPressed: () async {
                      if (await encaisser(context) && context.mounted) {
                        context.read<DashboardBloc>().add(
                          RafraichirDashboard(),
                        );
                      }
                    },
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Encaisser'),
                  ),
                );
              },
            ),
            body: BlocBuilder<DashboardBloc, DashboardState>(
              // Un échec de rafraîchissement laisse le tableau de bord affiché.
              buildWhen: (_, state) => state is! DashboardActionError,
              builder: (context, state) {
                if (state is! DashboardLoaded) {
                  return SafeArea(
                    child: VueChargement(
                      failure: state is DashboardError ? state.failure : null,
                      onReessayer: () =>
                          context.read<DashboardBloc>().add(LoadDashboard()),
                    ),
                  );
                }
                final d = state.tableauDeBord;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.dark,
                  child: RefreshIndicator(
                    onRefresh: () async => context.read<DashboardBloc>().add(
                      RafraichirDashboard(),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 104),
                      children: [
                        // Bandeau bleu derrière l'en-tête et le haut de la carte de synthèse.
                        Stack(
                          children: [
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 64,
                              // Dégradé du logo, coins bas arrondis.
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(
                                    AppTheme.rayonFeuille,
                                  ),
                                ),
                                child: FondMarque(),
                              ),
                            ),
                            Column(
                              children: [
                                _EnTete(
                                  d: d,
                                  onNotifications: () => _ouvrir(
                                    context,
                                    const NotificationsPage(),
                                  ),
                                  onProfil: () => onAller(4),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.espaceLg,
                                  ),
                                  child: _Synthese(d),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.espaceXl),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.espaceLg,
                            0,
                            AppTheme.espaceLg,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (lectureSeule) ...[
                                Encadre(
                                  'Votre abonnement est échu : vos données restent consultables mais ne peuvent plus être modifiées.',
                                  ton: TonStatut.danger,
                                  action: TextButton(
                                    onPressed: () =>
                                        context.push(AppRouter.abonnement),
                                    child: const Text('Renouveler'),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.espaceLg),
                              ],
                              _Titre('Ce mois-ci'),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: AppTheme.espaceMd,
                                crossAxisSpacing: AppTheme.espaceMd,
                                childAspectRatio: 1.18,
                                children: [
                                  ChiffreCle(
                                    libelle: 'Reste à recevoir',
                                    valeur: montant(d.resteARecevoir),
                                    icone: Icons.schedule,
                                    ton: TonStatut.info,
                                    sous:
                                        'sur ${montant(d.aRecevoir)} attendus',
                                  ),
                                  ChiffreCle(
                                    libelle: 'Encaissé',
                                    valeur: montant(d.revenus ?? d.encaisses),
                                    icone: Icons.check_circle_outline,
                                    ton: TonStatut.succes,
                                    sous:
                                        'dont ${montant(d.encaisses)} pour ce mois',
                                  ),
                                  ChiffreCle(
                                    libelle: 'Impayés',
                                    valeur: montant(d.impayes),
                                    icone: Icons.error_outline,
                                    ton: TonStatut.danger,
                                    sous: 'Tous mois confondus',
                                    onTap: () => _ouvrir(
                                      context,
                                      const EcheancesPage(impayes: true),
                                    ),
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
                                onTravaux: () => onAller(3),
                              ),
                              const SizedBox(height: AppTheme.espaceLg),
                              if (d.totalDebiteurs > 0) ...[
                                _Titre("Qui n'a pas payé ?"),
                                _Impayes(
                                  d: d,
                                  ouvrir: (w) => _ouvrir(context, w),
                                ),
                                const SizedBox(height: AppTheme.espaceLg),
                              ],
                              _Titre('Revenus et dépenses'),
                              _RevenusDepenses(d),
                              const SizedBox(height: AppTheme.espaceLg),
                              if (d.depensesParCategorie.isNotEmpty) ...[
                                _Titre('Dépenses par catégorie'),
                                Section(
                                  children: [
                                    for (final c in d.depensesParCategorie)
                                      Ligne(c.nom, montant(c.total)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Relit le tableau de bord au retour sur l'onglet et sur l'application.
class _Actualisation extends StatefulWidget {
  final Listenable? signal;
  final Widget child;
  const _Actualisation({required this.signal, required this.child});

  @override
  State<_Actualisation> createState() => _ActualisationState();
}

class _ActualisationState extends State<_Actualisation>
    with WidgetsBindingObserver {
  void _relire() => context.read<DashboardBloc>().add(RafraichirDashboard());

  @override
  void initState() {
    super.initState();
    widget.signal?.addListener(_relire);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.signal?.removeListener(_relire);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) _relire();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Bandeau au dégradé du logo : logo, notifications, mois et titre.
class _EnTete extends StatelessWidget {
  final TableauDeBord d;
  final VoidCallback onNotifications;
  final VoidCallback onProfil;
  const _EnTete({
    required this.d,
    required this.onNotifications,
    required this.onProfil,
  });

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    // Icônes de la barre d'état en blanc tant que le bandeau est dessous.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.espaceLg + 4,
          haut + AppTheme.espaceMd,
          AppTheme.espaceLg,
          AppTheme.espaceXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LogoBarre(marge: false),
                const SizedBox(width: 10),
                const NomKerimmo(taille: 20, surFonce: true),
                const Spacer(),
                IconButton(
                  tooltip: 'Notifications',
                  color: Colors.white,
                  icon: const BoutonNotifications(),
                  onPressed: onNotifications,
                ),
                const SizedBox(width: AppTheme.espaceXs),
                AvatarUtilisateur(onTap: onProfil),
              ],
            ),
            const SizedBox(height: AppTheme.espaceXl),
            Text(
              _majuscule(mois(d.mois)),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tableau de bord',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _majuscule(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

/// Carte blanche de synthèse du patrimoine (immeubles, appartements, occupation).
class _Synthese extends StatelessWidget {
  final TableauDeBord d;
  const _Synthese(this.d);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final taux = (d.tauxOccupation ?? 0).toDouble();
    Widget chiffre(String valeur, String libelle, {Color? couleur}) => Expanded(
      child: Column(
        children: [
          Text(
            valeur,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: couleur ?? p.texte,
            ).merge(chiffresFixes),
          ),
          const SizedBox(height: 2),
          Text(
            libelle,
            style: TextStyle(fontSize: 12, color: p.texteSecondaire),
          ),
        ],
      ),
    );
    Widget filet() => Container(width: 1, height: 36, color: p.bordure);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.espaceSm,
        AppTheme.espaceLg,
        AppTheme.espaceSm,
        AppTheme.espaceLg,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F2A55),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              chiffre(
                '${d.immeubles}',
                d.immeubles > 1 ? 'Immeubles' : 'Immeuble',
              ),
              filet(),
              chiffre(
                '${d.appartements}',
                d.appartements > 1 ? 'Appartements' : 'Appartement',
              ),
              filet(),
              chiffre(
                pourcent(d.tauxOccupation),
                'Occupation',
                couleur: AppColors.secondaireSurvol,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.espaceMd),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.espaceSm),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: taux / 100,
                    minHeight: 6,
                    color: AppColors.secondaire,
                    backgroundColor: p.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${d.occupes} ${d.occupes > 1 ? 'occupés' : 'occupé'}',
                      style: TextStyle(fontSize: 12, color: p.texteSecondaire),
                    ),
                    const Spacer(),
                    Text(
                      '${d.disponibles} ${d.disponibles > 1 ? 'disponibles' : 'disponible'}',
                      style: TextStyle(fontSize: 12, color: p.texteSecondaire),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.espaceMd, left: 2),
    child: Text(
      texte,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: context.palette.texte,
      ),
    ),
  );
}

class _ATraiter extends StatelessWidget {
  final TableauDeBord d;
  final void Function(Widget) ouvrir;
  final VoidCallback onTravaux;
  const _ATraiter({
    required this.d,
    required this.ouvrir,
    required this.onTravaux,
  });

  @override
  Widget build(BuildContext context) {
    final lignes = <(IconData, String, int, VoidCallback)>[
      (
        Icons.fact_check_outlined,
        'Preuves de paiement à valider',
        d.preuvesAValider,
        () => ouvrir(const TransactionsPage(aValider: true)),
      ),
      (
        Icons.compare_arrows,
        'Paiements à rapprocher',
        d.aRapprocher,
        () => ouvrir(const RapprochementsPage()),
      ),
      (
        Icons.water_drop_outlined,
        'Factures communes à répartir',
        d.facturesARepartir,
        () => ouvrir(const FacturesCommunesPage(statut: 'brouillon')),
      ),
      (
        Icons.report_problem_outlined,
        'Incidents ouverts',
        d.incidentsOuverts,
        () => ouvrir(const IncidentsPage(ouverts: true)),
      ),
      (
        Icons.handyman_outlined,
        'Travaux en cours',
        d.travauxEnCours,
        onTravaux,
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

/// Carte « Qui n'a pas payé ? » : total dû, puis une ligne par locataire
/// (logement, loyers en retard, ancienneté du retard, montant).
class _Impayes extends StatelessWidget {
  final TableauDeBord d;
  final void Function(Widget) ouvrir;
  const _Impayes({required this.d, required this.ouvrir});

  static const _maxLignes = 5;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = d.totalDebiteurs;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête : total dû et nombre de locataires concernés.
          Container(
            color: p.dangerFond,
            padding: const EdgeInsets.all(AppTheme.espaceLg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, color: p.danger, size: 22),
                ),
                const SizedBox(width: AppTheme.espaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total impayé',
                        style: TextStyle(
                          fontSize: 13,
                          color: p.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Montant(
                        d.impayes,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: p.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  n > 1 ? '$n locataires' : '1 locataire',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.danger,
                  ),
                ),
              ],
            ),
          ),
          for (final (i, x) in d.debiteurs.take(_maxLignes).indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppTheme.espaceLg,
                endIndent: AppTheme.espaceLg,
              ),
            _LigneImpaye(
              x,
              onTap: () => ouvrir(
                EcheancesPage(
                  impayes: true,
                  locataireId: x.locataire.id,
                  titre: x.locataire.nomComplet,
                ),
              ),
            ),
          ],
          const Divider(height: 1),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => ouvrir(const EcheancesPage(impayes: true)),
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
            label: Text(
              n > _maxLignes
                  ? 'Voir les $n impayés'
                  : 'Voir le détail des impayés',
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneImpaye extends StatelessWidget {
  final Debiteur x;
  final VoidCallback onTap;
  const _LigneImpaye(this.x, {required this.onTap});

  /// Jours écoulés depuis la plus ancienne échéance impayée.
  int? get _joursRetard {
    final d = DateTime.tryParse(x.depuis ?? '');
    if (d == null) return null;
    final j = DateTime.now().difference(d).inDays;
    return j < 0 ? 0 : j;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final logement = [
      x.immeuble,
      x.appartement,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
    final jours = _joursRetard;
    Widget puce(String texte) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.texteSecondaire,
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.espaceLg,
          AppTheme.espaceMd,
          AppTheme.espaceSm,
          AppTheme.espaceMd,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: p.primaireTeinte,
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                x.locataire.initiales,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppTheme.espaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    x.locataire.nomComplet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: p.texte,
                    ),
                  ),
                  if (logement.isNotEmpty)
                    Text(
                      logement,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.texteSecondaire),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (x.echeances > 0)
                        puce(
                          x.echeances > 1 ? '${x.echeances} loyers' : '1 loyer',
                        ),
                      if (jours != null) puce('$jours j de retard'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.espaceSm),
            Montant(
              x.montant,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.danger,
              ),
            ),
            Icon(Icons.chevron_right, color: p.texteDiscret),
          ],
        ),
      ),
    );
  }
}

/// Revenus et dépenses avec choix de la période (3, 6 ou 12 mois) :
/// totaux de la période, puis histogramme mois par mois.
class _RevenusDepenses extends StatefulWidget {
  final TableauDeBord d;
  const _RevenusDepenses(this.d);

  @override
  State<_RevenusDepenses> createState() => _RevenusDepensesState();
}

class _RevenusDepensesState extends State<_RevenusDepenses> {
  static const _periodes = [3, 6, 12];

  /// Le tableau de bord charge déjà 6 mois : pas de requête à l'ouverture.
  int _nbMois = 6;
  late SerieFinanciere _serie = _serieInitiale;
  bool _chargement = false;
  String? _erreur;

  SerieFinanciere get _serieInitiale => SerieFinanciere(
    revenus: widget.d.revenusMensuels,
    depenses: widget.d.depensesMensuelles,
  );

  @override
  void didUpdateWidget(covariant _RevenusDepenses ancien) {
    super.didUpdateWidget(ancien);
    // Tableau de bord rafraîchi : on recharge la période affichée.
    if (ancien.d != widget.d) {
      _nbMois == 6
          ? setState(() => _serie = _serieInitiale)
          : _charger(_nbMois);
    }
  }

  Future<void> _charger(int nbMois) async {
    setState(() {
      _nbMois = nbMois;
      _chargement = true;
      _erreur = null;
    });
    final r = await di.sl<DashboardRepository>().serieFinanciere(nbMois);
    if (!mounted || nbMois != _nbMois) return;
    setState(() {
      _chargement = false;
      r.fold((f) => _erreur = f.errorMessage, (s) => _serie = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    final revenus = _serie.totalRevenus;
    final depenses = _serie.totalDepenses;
    final resultat = revenus - depenses;
    Widget total(String libelle, num valeur, Color couleur) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                libelle,
                style: TextStyle(fontSize: 12, color: p.texteSecondaire),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Montant(
              valeur,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return Section(
      children: [
        // Filtre de période : contrôle segmenté.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.rayon),
          ),
          child: Row(
            children: [
              for (final n in _periodes)
                Expanded(
                  child: _Segment(
                    libelle: '$n mois',
                    actif: n == _nbMois,
                    onTap: n == _nbMois ? null : () => _charger(n),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Row(
          children: [
            total('Revenus', revenus, cs.primary),
            total('Dépenses', depenses, p.bordureForte),
            total(
              'Résultat',
              resultat,
              resultat < 0 ? p.danger : AppColors.secondaire,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        SizedBox(
          height: 190,
          child: _erreur != null
              ? Center(
                  child: TextButton.icon(
                    onPressed: () => _charger(_nbMois),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                )
              : AnimatedOpacity(
                  opacity: _chargement ? 0.35 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: _GraphiqueRevenus(_serie),
                ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String libelle;
  final bool actif;
  final VoidCallback? onTap;
  const _Segment({required this.libelle, required this.actif, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: actif ? Theme.of(context).colorScheme.surface : Colors.transparent,
    borderRadius: BorderRadius.circular(AppTheme.rayon - 3),
    elevation: actif ? 1 : 0,
    shadowColor: const Color(0x33101828),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppTheme.rayon - 3),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            libelle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: actif
                  ? Theme.of(context).colorScheme.primary
                  : context.palette.texteSecondaire,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Histogramme revenus (bleu) / dépenses (gris), un groupe par mois.
class _GraphiqueRevenus extends StatelessWidget {
  final SerieFinanciere serie;
  const _GraphiqueRevenus(this.serie);

  @override
  Widget build(BuildContext context) {
    final revenus = serie.revenus;
    final depenses = serie.depenses;
    final max = [
      ...revenus.map((r) => r.total),
      ...depenses.values,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;
    final p = context.palette;
    // Sur 12 mois : barres plus fines et un libellé sur deux.
    final dense = revenus.length > 6;
    final largeur = dense ? 7.0 : 11.0;
    return BarChart(
      BarChartData(
        maxY: max * 1.15,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: max * 1.15 / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.bordure, strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= revenus.length || (dense && i.isOdd)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    moisCourt(revenus[i].mois),
                    style: TextStyle(fontSize: 11, color: p.texteSecondaire),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cs.inverseSurface,
            getTooltipItem: (groupe, _, barre, i) => BarTooltipItem(
              '${i == 0 ? 'Revenus' : 'Dépenses'}\n${montant(barre.toY)}',
              TextStyle(color: cs.onInverseSurface, fontSize: 12),
            ),
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
                  width: largeur,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: (depenses[revenus[i].mois] ?? 0).toDouble(),
                  color: p.bordureForte,
                  width: largeur,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
