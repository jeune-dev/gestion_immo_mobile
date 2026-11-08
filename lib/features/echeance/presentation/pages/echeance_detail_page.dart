import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
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
  late Future<Either<Failure, EcheanceDetail>> _fiche = _charger();
  bool _modifiee = false;

  Future<Either<Failure, EcheanceDetail>> _charger() =>
      sl<GetEcheance>()(widget.id, espaceLocataire: widget.espaceLocataire);

  void _recharger() => setState(() => _fiche = _charger());

  void _apresAction(bool reussi) {
    if (!reussi || !mounted) return;
    _modifiee = true;
    _recharger();
  }

  Future<void> _annuler(EcheanceDetail d) async {
    final motif = await confirmer(
      context,
      titre: "Annuler l'échéance",
      message: 'Elle ne sera plus due par le locataire.',
      action: 'Annuler',
      danger: true,
      motif: true,
    );
    if (motif == null || !mounted) return;
    _apresAction(
      await reussir(
        context,
        () => sl<AnnulerEcheance>()(d.echeance.id, motif),
        succes: 'Échéance annulée',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (aQuitte, _) {
        if (!aQuitte) Navigator.of(context).pop(_modifiee);
      },
      child: FutureBuilder<Either<Failure, EcheanceDetail>>(
        future: _fiche,
        builder: (context, s) {
          if (!s.hasData) return const VueChargement(titre: 'Échéance');
          return s.data!.fold(
            (f) => VueChargement(
              titre: 'Échéance',
              failure: f,
              onReessayer: _recharger,
            ),
            (d) => _buildFiche(context, d),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, EcheanceDetail d) {
    final e = d.echeance;
    final payable = e.payable;
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
        onRefresh: () async => _recharger(),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          children: [
            CarteMarque(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LOYER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Statut(
                        FamilleStatut.echeance,
                        'statut_echeance',
                        e.statut,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  Text(
                    montant(payable ? e.reste : e.montantDu),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.espaceXs),
                  Text(
                    payable
                        ? 'Reste à payer · échéance ${date(e.dateEcheance)}'
                        : e.statut == 'paye' && d.payeeLe != null
                        ? 'Soldée le ${date(d.payeeLe)}'
                        : 'Échéance ${date(e.dateEcheance)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
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
                  for (final p in d.imputations)
                    TuileOption(
                      sansMarge: true,
                      icone: Icons.check_circle_outline,
                      titre: montant(p.montant),
                      detail: [
                        date(p.payeLe ?? p.imputeLe),
                        if (p.moyen != null)
                          refs.libelle('mode_paiement', p.moyen),
                        if (p.reference != null) p.reference!,
                      ].join(' · '),
                    ),
              ],
            ),
            if (d.quittance != null) ...[
              const SizedBox(height: AppTheme.espaceMd),
              Section(
                titre: 'Quittance',
                children: [
                  TuileOption(
                    sansMarge: true,
                    icone: Icons.description_outlined,
                    titre: d.quittance!.numero == null
                        ? 'Quittance'
                        : 'N° ${d.quittance!.numero}',
                    detail: 'Émise le ${date(d.quittance!.emiseLe)}',
                    fin: const Icon(Icons.chevron_right),
                    onTap: () => ouvrir(
                      context,
                      QuittanceDetailPage(
                        id: d.quittance!.id,
                        espaceLocataire: widget.espaceLocataire,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (payable) ...[
              const SizedBox(height: AppTheme.espaceLg),
              if (widget.espaceLocataire)
                if (e.bailId != null)
                  FilledButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: Text('Payer ${montant(e.reste)}'),
                    onPressed: () async => _apresAction(
                      await payer(context, echeance: e, bailId: e.bailId!) ==
                          true,
                    ),
                  )
                else
                  const SizedBox.shrink()
              else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Encaisser'),
                  onPressed: () async =>
                      _apresAction(await encaisser(context, echeance: e)),
                ),
                if (e.montantPaye == 0) ...[
                  const SizedBox(height: AppTheme.espaceSm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.block),
                    label: const Text("Annuler l'échéance"),
                    onPressed: () => _annuler(d),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
