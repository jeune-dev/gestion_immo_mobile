import 'package:flutter/material.dart';

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
class ChargeDetailPage extends StatelessWidget {
  final String id;
  const ChargeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) => FicheChargee<ChargeRefacturee>(
    titre: 'Charge',
    charger: () => sl<GetChargeRefacturee>()(id),
    fiche: (context, c, recharger) => Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(c.libelle ?? 'Charge'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => recharger(),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          children: [
            CarteMontant(
              surtitre: refs.libelle('type_charge', c.typeCharge),
              statut: Statut(FamilleStatut.charge, 'statut_charge', c.statut),
              montant: c.payable ? c.reste : c.montant,
              sousTitre: c.payable
                  ? 'Reste dû · échéance ${date(c.dateEcheance)}'
                  : 'Échéance ${date(c.dateEcheance)}',
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
            if (c.calcul case final k?) ..._repartition(c, k),
          ],
        ),
      ),
    ),
  );

  List<Widget> _repartition(ChargeRefacturee c, CalculCharge k) => [
    const SizedBox(height: AppTheme.espaceMd),
    Section(
      titre: 'Facture et répartition',
      children: [
        if (k.fournisseur != null) Ligne('Fournisseur', k.fournisseur),
        if (k.numeroFacture != null) Ligne('N° de facture', k.numeroFacture),
        if (k.periodeDebut != null || k.periodeFin != null)
          Ligne('Période', '${date(k.periodeDebut)} → ${date(k.periodeFin)}'),
        Ligne('Total de la facture', montant(k.totalFacture)),
        if (k.methode != null)
          Ligne(
            'Méthode',
            k.methodeLibelle ?? refs.libelle('methode_repartition', k.methode),
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
  ];
}
