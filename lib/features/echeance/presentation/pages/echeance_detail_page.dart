import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance_detail.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/annuler_echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/get_echeance.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/paiement_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittance_detail_page.dart';

/// Fiche d'une échéance (§ 11) : décomposition, paiements imputés, quittance.
///
/// Propriétaire : encaisser ou annuler. Locataire ([espaceLocataire]) : payer.
/// Renvoie `true` à la fermeture si l'échéance a changé (la liste se recharge).
class EcheanceDetailPage extends StatefulWidget {
  final String id;
  final bool espaceLocataire;
  const EcheanceDetailPage({
    super.key,
    required this.id,
    this.espaceLocataire = false,
  });

  @override
  State<EcheanceDetailPage> createState() => _EcheanceDetailPageState();
}

class _EcheanceDetailPageState extends State<EcheanceDetailPage> {
  bool _modifiee = false;

  void _apresAction(bool reussi, VoidCallback recharger) {
    if (!reussi || !mounted) return;
    _modifiee = true;
    recharger();
  }

  Future<void> _annuler(EcheanceDetail d, VoidCallback recharger) async {
    final motif = await confirmer(
      context,
      titre: "Annuler l'échéance",
      message: 'Elle ne sera plus due par le locataire.',
      action: 'Annuler',
      danger: true,
      motif: true,
    );
    if (motif == null || !mounted) return;
    final reussi = await reussir(
      context,
      () => sl<AnnulerEcheance>()(d.echeance.id, motif),
      succes: 'Échéance annulée',
    );
    _apresAction(reussi, recharger);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (aQuitte, _) {
        if (!aQuitte) Navigator.of(context).pop(_modifiee);
      },
      child: FicheChargee<EcheanceDetail>(
        titre: 'Échéance',
        charger: () => sl<GetEcheance>()(
          widget.id,
          espaceLocataire: widget.espaceLocataire,
        ),
        fiche: _buildFiche,
      ),
    );
  }

  Widget _buildFiche(
    BuildContext context,
    EcheanceDetail d,
    VoidCallback recharger,
  ) {
    final e = d.echeance;
    final logement = [
      if (d.immeuble != null) d.immeuble!,
      if (e.logementNumero != null) 'Appartement ${e.logementNumero}',
    ].join(' · ');
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(e.libelle ?? 'Échéance'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => recharger(),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          children: [
            CarteMontant(
              surtitre: 'Loyer',
              statut: Statut(
                FamilleStatut.echeance,
                'statut_echeance',
                e.statut,
              ),
              montant: e.payable ? e.reste : e.montantDu,
              sousTitre: _sousTitre(d),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Détail',
              children: [
                if (!widget.espaceLocataire && e.locataire != null)
                  Ligne('Locataire', nomDe(e.locataire)),
                if (logement.isNotEmpty) Ligne('Logement', logement),
                if (d.periodeDebut != null || d.periodeFin != null)
                  Ligne(
                    'Période',
                    '${date(d.periodeDebut)} → ${date(d.periodeFin)}',
                  ),
                if (d.loyer != null) Ligne('Loyer', montant(d.loyer)),
                if (d.charges != null && d.charges! > 0)
                  Ligne('Provision sur charges', montant(d.charges)),
                Ligne('Montant dû', montant(e.montantDu)),
                Ligne('Déjà payé', montant(e.montantPaye)),
                if (e.statut != 'annule') Ligne('Reste', montant(e.reste)),
              ],
            ),
            const SizedBox(height: AppTheme.espaceMd),
            Section(
              titre: 'Paiements',
              children: [
                if (d.imputations.isEmpty)
                  const Ligne('Aucun paiement pour le moment', null)
                else
                  for (final p in d.imputations) _TuileImputation(p),
              ],
            ),
            if (d.quittance case final q?) ...[
              const SizedBox(height: AppTheme.espaceMd),
              Section(
                titre: 'Quittance',
                children: [
                  TuileOption(
                    sansMarge: true,
                    icone: Icons.description_outlined,
                    titre: q.numero == null ? 'Quittance' : 'N° ${q.numero}',
                    detail: 'Émise le ${date(q.emiseLe)}',
                    fin: const Icon(Icons.chevron_right),
                    onTap: () => ouvrir(
                      context,
                      QuittanceDetailPage(
                        id: q.id,
                        espaceLocataire: widget.espaceLocataire,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (e.payable) ...[
              const SizedBox(height: AppTheme.espaceLg),
              ...(widget.espaceLocataire
                  ? _actionsLocataire(context, d, recharger)
                  : _actionsProprietaire(context, d, recharger)),
            ],
          ],
        ),
      ),
    );
  }

  String _sousTitre(EcheanceDetail d) {
    final e = d.echeance;
    if (e.payable) return 'Reste à payer · échéance ${date(e.dateEcheance)}';
    if (e.statut == 'paye' && d.payeeLe != null) {
      return 'Soldée le ${date(d.payeeLe)}';
    }
    return 'Échéance ${date(e.dateEcheance)}';
  }

  /// Le locataire paie en ligne (le bail est nécessaire au choix du moyen).
  List<Widget> _actionsLocataire(
    BuildContext context,
    EcheanceDetail d,
    VoidCallback recharger,
  ) {
    final e = d.echeance;
    final bailId = e.bailId;
    if (bailId == null) return const [];
    return [
      FilledButton.icon(
        icon: const Icon(Icons.payments_outlined),
        label: Text('Payer ${montant(e.reste)}'),
        onPressed: () async {
          final paye = await payer(context, echeance: e, bailId: bailId);
          _apresAction(paye == true, recharger);
        },
      ),
    ];
  }

  /// Le propriétaire encaisse ; il peut annuler une échéance encore vierge.
  List<Widget> _actionsProprietaire(
    BuildContext context,
    EcheanceDetail d,
    VoidCallback recharger,
  ) {
    final e = d.echeance;
    return [
      FilledButton.icon(
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Encaisser'),
        onPressed: () async =>
            _apresAction(await encaisser(context, echeance: e), recharger),
      ),
      if (e.montantPaye == 0) ...[
        const SizedBox(height: AppTheme.espaceSm),
        OutlinedButton.icon(
          icon: const Icon(Icons.block),
          label: const Text("Annuler l'échéance"),
          onPressed: () => _annuler(d, recharger),
        ),
      ],
    ];
  }
}

/// Paiement imputé : montant, date, moyen et référence.
class _TuileImputation extends StatelessWidget {
  final ImputationPaiement p;
  const _TuileImputation(this.p);

  @override
  Widget build(BuildContext context) => TuileOption(
    sansMarge: true,
    icone: Icons.check_circle_outline,
    titre: montant(p.montant),
    detail: [
      date(p.payeLe ?? p.imputeLe),
      if (p.moyen != null) refs.libelle('mode_paiement', p.moyen),
      if (p.reference != null) p.reference!,
    ].join(' · '),
  );
}
