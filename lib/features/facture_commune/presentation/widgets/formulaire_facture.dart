import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/sources_immeuble.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/creer_facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/modifier_facture_commune.dart';

/// Champs d'une facture commune, communs à la création et à la modification du brouillon.
List<Champ> _champsFacture() => [
      Champ('building_id', 'Immeuble',
          type: TypeChamp.entite, obligatoire: true, entite: sourceImmeubles()),
      const Champ('charge_type', 'Type de charge',
          type: TypeChamp.selection,
          referentiel: 'type_charge',
          obligatoire: true),
      const Champ('supplier', 'Fournisseur',
          maxLongueur: 120, indice: 'Ex. SENELEC, SEN’EAU'),
      const Champ('invoice_number', 'N° de facture', maxLongueur: 60),
      const Champ('amount', 'Montant total',
          type: TypeChamp.montant, obligatoire: true, min: 1),
      const Champ('period_start', 'Début de période',
          type: TypeChamp.date, obligatoire: true),
      const Champ('period_end', 'Fin de période',
          type: TypeChamp.date, obligatoire: true),
      const Champ('due_date', 'Date limite de paiement',
          type: TypeChamp.date, nullable: true),
      const Champ('allocation_method', 'Méthode de répartition',
          type: TypeChamp.selection,
          referentiel: 'methode_repartition',
          obligatoire: true),
      const Champ('recharge_to_tenants', 'Refacturer aux locataires',
          type: TypeChamp.interrupteur),
      const Champ('notes', 'Notes',
          type: TypeChamp.multiligne, maxLongueur: 5000),
    ];

/// Nouvelle facture commune (brouillon) ; la répartition se fait ensuite.
Future<FactureCommune?> creerFactureCommune(BuildContext context) {
  final cle = nouvelleCle();
  return EcranFormulaire.ouvrir<FactureCommune>(
    context,
    EcranFormulaire(
      titre: 'Nouvelle facture commune',
      initial: const {'recharge_to_tenants': true},
      intro: const Text(
          'La méthode de répartition est obligatoire (§ 41). Vous pourrez prévisualiser la répartition avant de la valider.'),
      champs: _champsFacture(),
      messageSucces: 'Facture enregistrée',
      envoyer: (c) async =>
          (await sl<CreerFactureCommune>()(c, cle: cle)).ouLeve(),
    ),
  );
}

/// Modification d'une facture encore en brouillon.
Future<FactureCommune?> modifierFactureCommune(
    BuildContext context, FactureCommune f) {
  return EcranFormulaire.ouvrir<FactureCommune>(
    context,
    EcranFormulaire(
      titre: 'Modifier la facture',
      initial: {
        'building_id': f.immeubleId,
        'building_id__libelle': f.immeubleNom,
        'charge_type': f.typeCharge,
        'supplier': f.fournisseur,
        'invoice_number': f.numeroFacture,
        'amount': f.montant?.round(),
        'period_start': f.debutPeriode,
        'period_end': f.finPeriode,
        'due_date': f.dateLimite,
        'allocation_method': f.methodeRepartition,
        'recharge_to_tenants': f.refacturer,
        'notes': f.notes,
      },
      champs: _champsFacture(),
      messageSucces: 'Facture modifiée',
      envoyer: (c) async =>
          (await sl<ModifierFactureCommune>()(f.id, c)).ouLeve(),
    ),
  );
}
