import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/get_charge_refacturee.dart';

/// Fiche d'une charge refacturée (§ 15) : locataire, facture d'origine et
/// part du logement.
class ChargeDetailPage extends StatefulWidget {
  final String id;
  const ChargeDetailPage({super.key, required this.id});

  @override
  State<ChargeDetailPage> createState() => _ChargeDetailPageState();
}

class _ChargeDetailPageState extends State<ChargeDetailPage> {
  late Future<Either<Failure, ChargeRefacturee>> _fiche = _charger();

  Future<Either<Failure, ChargeRefacturee>> _charger() =>
      sl<GetChargeRefacturee>()(widget.id);

  void _recharger() => setState(() => _fiche = _charger());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, ChargeRefacturee>>(
      future: _fiche,
      builder: (context, s) {
        if (!s.hasData) return const VueChargement(titre: 'Charge');
        return s.data!.fold(
          (f) => VueChargement(
            titre: 'Charge',
            failure: f,
            onReessayer: _recharger,
          ),
          (c) => _buildFiche(context, c),
        );
      },
    );
  }

  Widget _buildFiche(BuildContext context, ChargeRefacturee c) {
    final k = c.calcul;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(c.libelle ?? 'Charge'),
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
                          refs
                              .libelle('type_charge', c.typeCharge)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Statut(FamilleStatut.charge, 'statut_charge', c.statut),
                    ],
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  Text(
                    montant(c.payable ? c.reste : c.montant),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.espaceXs),
                  Text(
                    c.payable
                        ? 'Reste dû · échéance ${date(c.dateEcheance)}'
                        : 'Échéance ${date(c.dateEcheance)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Détail',
              children: [
                if (c.locataire != null) Ligne('Locataire', nomDe(c.locataire)),
                if (c.logementNumero != null)
                  Ligne('Logement', 'Appartement ${c.logementNumero}'),
                Ligne('Montant', montant(c.montant)),
                Ligne('Déjà payé', montant(c.montantPaye)),
                if (c.statut != 'annule') Ligne('Reste', montant(c.reste)),
              ],
            ),
            if (k != null) ...[
              const SizedBox(height: AppTheme.espaceMd),
              Section(
                titre: 'Facture et répartition',
                children: [
                  if (k.fournisseur != null)
                    Ligne('Fournisseur', k.fournisseur),
                  if (k.numeroFacture != null)
                    Ligne('N° de facture', k.numeroFacture),
                  if (k.periodeDebut != null || k.periodeFin != null)
                    Ligne(
                      'Période',
                      '${date(k.periodeDebut)} → ${date(k.periodeFin)}',
                    ),
                  Ligne('Total de la facture', montant(k.totalFacture)),
                  if (k.methode != null)
                    Ligne(
                      'Méthode',
                      k.methodeLibelle ??
                          refs.libelle('methode_repartition', k.methode),
                    ),
                  if (k.provisionDeduite > 0)
                    Ligne('Provision déduite', montant(k.provisionDeduite)),
                  Ligne('Part du logement', montant(c.montant)),
                ],
              ),
              if (k.explication != null && k.explication!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.espaceSm),
                Encadre(k.explication!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
