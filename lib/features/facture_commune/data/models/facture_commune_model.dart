import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/facture_commune.dart';

LigneRepartition _ligne(Map<String, dynamic> l) => LigneRepartition(
      logementNumero:
          ((l['apartment'] as Map?)?['number'] ?? l['apartment_number'])
              ?.toString(),
      locataire:
          PersonneResume.depuis(l['tenant'] ?? (l['lease'] as Map?)?['tenant']),
      explication: l['explanation'] as String?,
      montant: nombreOuNull(l['amount']),
    );

class FactureCommuneModel extends FactureCommune {
  const FactureCommuneModel({
    required super.id,
    super.typeCharge,
    super.immeubleId,
    super.immeubleNom,
    super.fournisseur,
    super.numeroFacture,
    super.montant,
    super.debutPeriode,
    super.finPeriode,
    super.dateLimite,
    super.methodeRepartition,
    super.refacturer,
    super.notes,
    super.statut,
    super.repartition,
  });

  factory FactureCommuneModel.fromJson(Map<String, dynamic> json) =>
      FactureCommuneModel(
        id: '${json['id']}',
        typeCharge: json['charge_type'] as String?,
        immeubleId: json['building_id']?.toString(),
        immeubleNom: (json['building'] as Map?)?['name'] as String?,
        fournisseur: json['supplier'] as String?,
        numeroFacture: json['invoice_number'] as String?,
        montant: nombreOuNull(json['amount']),
        debutPeriode: (json['period_start'] as String?)?.substring(0, 10),
        finPeriode: (json['period_end'] as String?)?.substring(0, 10),
        dateLimite: json['due_date'] as String?,
        methodeRepartition: json['allocation_method'] as String?,
        refacturer: json['recharge_to_tenants'] == true,
        notes: json['notes'] as String?,
        statut: json['status'] as String?,
        repartition: listeJson(json['allocations']).map(_ligne).toList(),
      );
}

class ApercuRepartitionModel extends ApercuRepartition {
  const ApercuRepartitionModel(
      {required super.lignes, super.totalRefacture, super.partProprietaire});

  factory ApercuRepartitionModel.fromJson(Map<String, dynamic> json) =>
      ApercuRepartitionModel(
        lignes: listeJson(json['lines']).map(_ligne).toList(),
        totalRefacture: nombreOuNull(json['recharged_total']),
        partProprietaire: nombreOuNull(json['owner_share']),
      );
}

class ChargeRefactureeModel extends ChargeRefacturee {
  const ChargeRefactureeModel({
    required super.id,
    super.libelle,
    super.typeCharge,
    super.locataire,
    super.logementNumero,
    super.dateEcheance,
    super.montant,
    super.montantPaye,
    super.statut,
  });

  factory ChargeRefactureeModel.fromJson(Map<String, dynamic> json) =>
      ChargeRefactureeModel(
        id: '${json['id']}',
        libelle: json['label'] as String?,
        typeCharge: json['charge_type'] as String?,
        locataire: PersonneResume.depuis(json['tenant']),
        logementNumero: (json['apartment'] as Map?)?['number']?.toString(),
        dateEcheance: json['due_date'] as String?,
        montant: entier(json['amount']),
        montantPaye: entier(json['amount_paid']),
        statut: json['status'] as String?,
      );
}
