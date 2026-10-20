import 'dart:io';

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/choix_periode.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/entities/rapports.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/usecases/exporter_rapport_csv.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/usecases/get_rapport_financier.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/usecases/get_rapport_immobilier.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/usecases/get_rapport_locataires.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/usecases/get_rapport_travaux.dart';
import 'package:gestion_immo_mobile/features/rapport/domain/usecases/get_rentabilite.dart';
import 'package:gestion_immo_mobile/features/rapport/presentation/bloc/rapport_bloc.dart';
import 'package:gestion_immo_mobile/features/rapport/presentation/bloc/rapport_event.dart';
import 'package:gestion_immo_mobile/features/rapport/presentation/bloc/rapport_state.dart';

/// Rapports (§ 26) : financier, immobilier, travaux, locataires, rentabilité (§ 4.21).
class RapportsPage extends StatefulWidget {
  const RapportsPage({super.key});

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage>
    with SingleTickerProviderStateMixin {
  static const _types = [
    ('financier', 'Financier'),
    ('immobilier', 'Occupation'),
    ('rentabilite', 'Rentabilité'),
    ('locataires', 'Locataires'),
    ('travaux', 'Travaux'),
  ];
  late final _onglets = TabController(length: _types.length, vsync: this);
  Periode _periode = Periode.anneeCourante();

  Future<void> _exporter() async {
    final type = _types[_onglets.index].$1;
    afficherSucces(context, 'Préparation de l’export…');
    final r =
        await sl<ExporterRapportCsv>()(type, du: _periode.du, au: _periode.au);
    await r.fold(
      (f) async {
        if (mounted) afficherErreurApi(context, f);
      },
      (octets) async {
        final f = File(
            '${(await getTemporaryDirectory()).path}/rapport-$type-${_periode.du}-${_periode.au}.csv');
        await f.writeAsBytes(octets, flush: true);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(f.path, mimeType: 'text/csv')],
            subject: 'Rapport $type',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final du = _periode.du, au = _periode.au;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        actions: [
          IconButton(
              tooltip: 'Exporter (CSV)',
              onPressed: _exporter,
              icon: const Icon(Icons.ios_share))
        ],
        bottom: TabBar(
          controller: _onglets,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(context)
              .appBarTheme
              .foregroundColor
              ?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: [for (final t in _types) Tab(text: t.$2)],
        ),
      ),
      body: Column(
        children: [
          ChoixPeriode(
              periode: _periode, onChange: (p) => setState(() => _periode = p)),
          Expanded(
            child: TabBarView(
              controller: _onglets,
              children: [
                _Rapport<RapportFinancier>(
                  cle: _periode,
                  lire: () => sl<GetRapportFinancier>()(du: du, au: au),
                  builder: _financier,
                ),
                _Rapport<RapportImmobilier>(
                  cle: _periode,
                  lire: () => sl<GetRapportImmobilier>()(du: du, au: au),
                  builder: _immobilier,
                ),
                _Rentabilite(periode: _periode),
                _Rapport<RapportLocataires>(
                  cle: _periode,
                  lire: () => sl<GetRapportLocataires>()(du: du, au: au),
                  builder: _locataires,
                ),
                _Rapport<RapportTravaux>(
                  cle: _periode,
                  lire: () => sl<GetRapportTravaux>()(du: du, au: au),
                  builder: _travaux,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _financier(BuildContext context, RapportFinancier r) => [
        Section(
          titre: 'Résultat',
          children: [
            Ligne('Loyers', montant(r.loyers)),
            Ligne('Charges récupérées', montant(r.chargesRecuperees)),
            Ligne('Autres revenus', montant(r.autresRevenus)),
            Ligne('Total revenus', montant(r.totalRevenus)),
            Ligne('Dépenses', montant(r.totalDepenses)),
            const Divider(),
            Ligne(
              'Bénéfice net',
              null,
              widget: Montant(
                r.beneficeNet,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: (r.beneficeNet ?? 0) < 0
                      ? context.palette.danger
                      : context.palette.succes,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Impayés au ${date(r.impayesDate)}',
          children: [
            Ligne('Montant', montant(r.impayesMontant)),
            Ligne('Échéances', '${r.impayesEcheances}'),
            Ligne('Locataires', '${r.impayesLocataires}'),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Dépenses par catégorie',
          children: [
            for (final c in r.depensesParCategorie)
              Ligne(c.libelle, montant(c.montant)),
            if (r.depensesParCategorie.isEmpty) const Text('Aucune dépense'),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Charges',
          children: [
            Ligne('Factures communes',
                '${r.nombreFactures} · ${montant(r.facturesTotal)}'),
            Ligne('Refacturées', montant(r.chargesRefacturees)),
            Ligne('Récupérées', montant(r.chargesRecupereesLocataires)),
            Ligne('Reste à recouvrer', montant(r.resteARecouvrer)),
            Ligne(
                'À la charge du propriétaire', montant(r.aChargeProprietaire)),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Par immeuble',
          padding: false,
          children: [
            for (final b in r.parImmeuble)
              ListTile(
                title: Text(b.nom),
                subtitle: Text(
                    'Revenus ${montant(b.revenus)} · dépenses ${montant(b.depenses)} · impayés ${montant(b.impayes)}'),
                trailing: Montant(b.beneficeNet,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ];

  static List<Widget> _immobilier(BuildContext context, RapportImmobilier r) =>
      [
        Section(
          titre: 'Occupation',
          children: [
            Ligne('Immeubles', '${r.immeubles}'),
            Ligne('Appartements', '${r.appartements}'),
            Ligne('Occupés', '${r.occupes}'),
            Ligne('Disponibles', '${r.disponibles}'),
            Ligne('En travaux', '${r.enTravaux}'),
            Ligne("Taux d'occupation", pourcent(r.tauxOccupation)),
            Ligne(
                'Occupation sur la période', pourcent(r.tauxOccupationPeriode)),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Loyers',
          children: [
            Ligne('Loyers mensuels (occupés)', montant(r.loyerMensuelOccupes)),
            Ligne('Loyer moyen', montant(r.loyerMoyen)),
            Ligne('Loyer potentiel', montant(r.loyerPotentiel)),
            Ligne('Manque à gagner (vacance)', montant(r.manqueAGagner)),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Par immeuble',
          padding: false,
          children: [
            for (final b in r.parImmeuble)
              ListTile(
                title: Text(b.nom),
                subtitle: Text(
                    '${b.occupes} occupés sur ${b.appartements} · ${b.ville ?? ''}'),
                trailing:
                    Text(pourcent(b.tauxOccupation), style: chiffresFixes),
              ),
          ],
        ),
      ];

  static List<Widget> _locataires(BuildContext context, RapportLocataires r) =>
      [
        Section(
          children: [
            Ligne('Locataires actifs', '${r.actifs}'),
            Ligne('Arrivées', '${r.nombreArrivees}'),
            Ligne('Départs', '${r.nombreDeparts}'),
            Ligne('Impayés', montant(r.impayesTotal)),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Locataires en impayé',
          padding: false,
          children: [
            for (final t in r.enImpaye)
              ListTile(
                  title: Text(t.nom),
                  subtitle: Text(
                      '${t.echeances} échéance(s) · depuis le ${date(t.depuis)}'),
                  trailing: Montant(t.montant)),
            if (r.enImpaye.isEmpty) const ListTile(title: Text('Aucun impayé')),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Arrivées',
          padding: false,
          children: [
            for (final b in r.arrivees)
              ListTile(
                  title: Text(b.nom),
                  subtitle: Text(
                      '${b.immeuble ?? ''} · ${b.appartement ?? ''} · ${date(b.date)}')),
          ],
        ),
        if (r.departs.isNotEmpty) ...[
          const SizedBox(height: AppTheme.espaceLg),
          Section(
            titre: 'Départs',
            padding: false,
            children: [
              for (final b in r.departs)
                ListTile(
                    title: Text(b.nom),
                    subtitle: Text(
                        '${b.immeuble ?? ''} · ${b.appartement ?? ''} · ${date(b.date)}')),
            ],
          ),
        ],
      ];

  static List<Widget> _travaux(BuildContext context, RapportTravaux r) => [
        Section(
          children: [
            Ligne('Créés sur la période', '${r.crees}'),
            Ligne('Terminés', '${r.termines}'),
            Ligne('En cours', '${r.enCours}'),
            Ligne('En attente', '${r.enAttente}'),
            Ligne('Annulés', '${r.annules}'),
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Coûts',
          children: [
            Ligne('Estimés', montant(r.coutEstime)),
            Ligne('Réels', montant(r.coutReel)),
            Ligne('Dépenses liées', montant(r.depensesLiees))
          ],
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Section(
          titre: 'Par catégorie',
          padding: false,
          children: [
            for (final c in r.parCategorie)
              ListTile(
                title: Text(refs.libelle('categorie_travaux', c.categorie)),
                subtitle:
                    Text('${c.nombre} chantier(s) · ${c.termines} terminé(s)'),
                trailing: Montant(c.coutReel),
              ),
          ],
        ),
      ];
}

/// Onglet d'un rapport, relu à chaque changement de période.
class _Rapport<T> extends StatelessWidget {
  final Periode cle;
  final Future<Either<Failure, T>> Function() lire;
  final List<Widget> Function(BuildContext, T) builder;
  const _Rapport(
      {required this.cle, required this.lire, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RapportBloc<T>>(
      key: ValueKey('${cle.du}|${cle.au}'),
      create: (_) => RapportBloc<T>(lireRapport: lire)..add(LoadRapport()),
      child: BlocBuilder<RapportBloc<T>, RapportState>(
        // Un échec de rafraîchissement laisse le rapport affiché.
        buildWhen: (_, state) => state is! RapportActionError,
        builder: (context, state) {
          if (state is! RapportLoaded<T>) {
            return VueChargement(
              failure: state is RapportError ? state.failure : null,
              onReessayer: () =>
                  context.read<RapportBloc<T>>().add(LoadRapport()),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<RapportBloc<T>>().add(RafraichirRapport()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: builder(context, state.rapport),
            ),
          );
        },
      ),
    );
  }
}

/// Rentabilité de chaque appartement, classée par résultat net (§ 48).
class _Rentabilite extends StatelessWidget {
  final Periode periode;
  const _Rentabilite({required this.periode});

  @override
  Widget build(BuildContext context) {
    return ListePaginee<LigneRentabilite>(
      cle: '${periode.du}|${periode.au}',
      vide: 'Aucun appartement',
      charger: (page) =>
          sl<GetRentabilite>()(page: page, du: periode.du, au: periode.au),
      element: (context, a) => ListTile(
        leading: CircleAvatar(child: Text('${a.rang ?? ''}')),
        title: Text('${a.immeuble ?? ''} · ${a.appartement ?? ''}'),
        subtitle: Text(
            'Revenus ${montant(a.revenus)} · dépenses ${montant(a.depenses)} · occupé ${pourcent(a.tauxOccupation)}'),
        trailing: Montant(
          a.resultatNet,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: (a.resultatNet ?? 0) < 0
                  ? context.palette.danger
                  : context.palette.succes),
        ),
      ),
    );
  }
}
