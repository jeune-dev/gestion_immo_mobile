import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeance_detail_page.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_echeances.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_paiements.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_transactions.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/paiement_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/widgets/choix_paiement.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/widgets/demarches_locataire.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// « Mon loyer » et « Mes paiements » (§ 28).
class LoyerPage extends StatefulWidget {
  const LoyerPage({super.key});

  @override
  State<LoyerPage> createState() => _LoyerPageState();
}

class _LoyerPageState extends State<LoyerPage>
    with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 3, vsync: this);
  final _echeances = GlobalKey<ListePagineeState<Echeance>>();
  bool _aPayer = true;

  @override
  void dispose() {
    _onglets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        leading: LogoBarre.siRacine(context),
        leadingWidth: LogoBarre.largeur,

        title: const Text('Mon loyer'),
        actions: [
          IconButton(
            tooltip: 'Mes quittances',
            icon: const Icon(Icons.description_outlined),
            onPressed: () =>
                ouvrir(context, const QuittancesPage(espaceLocataire: true)),
          ),
        ],
        bottom: TabBar(
          controller: _onglets,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(text: 'Échéances'),
            Tab(text: 'Paiements'),
            Tab(text: 'En ligne'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _onglets,
        children: [
          Column(
            children: [
              Filtres(
                options: const [('a_payer', 'À payer'), ('toutes', 'Toutes')],
                valeur: _aPayer ? 'a_payer' : 'toutes',
                onChange: (v) => setState(() => _aPayer = v == 'a_payer'),
              ),
              Expanded(
                child: ListePaginee<Echeance>(
                  key: _echeances,
                  cle: _aPayer,
                  vide: _aPayer
                      ? 'Vous êtes à jour : rien à payer'
                      : 'Aucune échéance',
                  iconeVide: _aPayer
                      ? Icons.verified_outlined
                      : Icons.event_outlined,
                  charger: (page) =>
                      sl<GetMesEcheances>()(page: page, aPayer: _aPayer),
                  element: (context, e) => TuileEcheance(
                    e,
                    onTap: () async {
                      final modifiee = await ouvrir<bool>(
                        context,
                        EcheanceDetailPage(id: e.id, espaceLocataire: true),
                      );
                      if (modifiee == true) {
                        _echeances.currentState?.recharger();
                      }
                    },
                    onPayer: e.payable && e.bailId != null
                        ? () async {
                            if (await payer(
                                  context,
                                  echeance: e,
                                  bailId: e.bailId!,
                                ) ==
                                true) {
                              _echeances.currentState?.recharger();
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
          ListePaginee<Paiement>(
            vide: 'Aucun paiement enregistré',
            charger: (page) => sl<GetMesPaiements>()(page: page),
            element: (context, p) => TuileOption(
              icone: Icons.check_circle_outline,
              titre: montant(p.montant),
              detail:
                  '${date(p.payeLe)} · ${refs.libelle('mode_paiement', p.moyen)}${p.reference == null ? '' : ' · ${p.reference}'}'
                  '${p.contestation == 'conteste' ? ' · contestation envoyée' : p.contestation == 'resolu' ? ' · réponse reçue' : ''}',
              fin: Statut(FamilleStatut.paiement, 'statut_paiement', p.statut),
              onTap: () => _actionsPaiement(context, p),
            ),
          ),
          ListePaginee<TransactionPaiement>(
            vide: 'Aucun paiement en ligne',
            charger: (page) => sl<GetMesTransactions>()(page: page),
            element: (context, t) => InkWell(
              onTap: () => ouvrir(
                context,
                SuiviTransactionPage(id: t.id, checkoutUrl: t.checkoutUrl),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.espaceMd),
                child: Row(
                  children: [
                    PastilleMoyen(portefeuille: t.portefeuille),
                    const SizedBox(width: AppTheme.espaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            montant(t.montant),
                            style: TextStyle(
                              color: context.palette.texte,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${refs.libelle('portefeuille', t.portefeuille)} · ${dateHeure(t.creeLe)}',
                            style: TextStyle(
                              color: context.palette.texteSecondaire,
                              fontSize: 13,
                            ),
                          ),
                          if (t.motifRejet != null)
                            Text(
                              'Refusé : ${t.motifRejet}',
                              style: TextStyle(
                                color: context.palette.danger,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.espaceSm),
                    Statut(
                      FamilleStatut.transaction,
                      'statut_transaction',
                      t.statut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Échéance : pastille de date, libellé, montant et bouton de paiement.
class TuileEcheance extends StatelessWidget {
  final Echeance e;
  final VoidCallback? onPayer;
  final VoidCallback? onTap;
  const TuileEcheance(this.e, {super.key, this.onPayer, this.onTap});

  static const _mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enRetard = e.statut == 'en_retard';
    final jour = e.dateEcheance == null
        ? null
        : DateTime.tryParse(e.dateEcheance!);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.espaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enRetard ? p.dangerFond : p.primaireTeinte,
                    borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        jour == null ? '—' : '${jour.day}',
                        style: TextStyle(
                          color: enRetard
                              ? p.danger
                              : Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      if (jour != null)
                        Text(
                          _mois[jour.month - 1],
                          style: TextStyle(
                            color: p.texteSecondaire,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.espaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.libelle ?? 'Échéance',
                        style: TextStyle(
                          color: p.texte,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Montant(
                        e.payable ? e.reste : e.montantDu,
                        style: TextStyle(
                          color: enRetard ? p.danger : p.texte,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (e.montantPaye > 0)
                        Text(
                          'Déjà payé : ${montant(e.montantPaye)}',
                          style: TextStyle(
                            color: p.texteSecondaire,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Statut(FamilleStatut.echeance, 'statut_echeance', e.statut),
              ],
            ),
            if (onPayer != null) ...[
              const SizedBox(height: AppTheme.espaceMd),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: onPayer,
                child: const Text('Payer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reçu du paiement ; contestation si le bailleur l'a remboursé.
Future<void> _actionsPaiement(BuildContext context, Paiement p) async {
  final choix = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Voir le reçu'),
            subtitle: const Text('Preuve de ce versement, même partiel'),
            onTap: () => Navigator.pop(ctx, 'recu'),
          ),
          if (p.statut == 'rembourse' && p.contestation == null)
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Contester le remboursement'),
              subtitle: const Text('Argent non reçu, montant différent…'),
              onTap: () => Navigator.pop(ctx, 'contester'),
            ),
          if (p.reponseContestation != null)
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Réponse de votre bailleur'),
              subtitle: Text(p.reponseContestation!),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choix == 'recu') {
    await ouvrirRecuPaiement(context, p.id, p.reference);
  } else if (choix == 'contester') {
    await contesterRemboursement(context, p.id);
  }
}
