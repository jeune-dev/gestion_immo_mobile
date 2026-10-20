import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/documents/data/models/document_model.dart';
import '../../domain/entities/paiement.dart';

class PaiementModel extends Paiement {
  const PaiementModel({
    required super.id,
    super.reference,
    super.montant,
    super.statut,
    super.locataire,
    super.logementNumero,
    super.moyen,
    super.payeLe,
    super.commentaire,
    super.rembourseLe,
    super.motifRemboursement,
    super.imputations,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) => PaiementModel(
        id: '${json['id']}',
        reference: json['reference'] as String?,
        montant: nombreOuNull(json['amount']),
        statut: json['status'] as String?,
        locataire: PersonneResume.depuis(json['tenant']),
        logementNumero: (json['apartment'] as Map?)?['number']?.toString(),
        moyen: json['method'] as String?,
        payeLe: json['paid_on'] as String?,
        commentaire: json['comment'] as String?,
        rembourseLe: json['refunded_at'] as String?,
        motifRemboursement: json['refund_reason'] as String?,
        imputations: listeJson(json['allocations'])
            .map(
              (a) => Imputation(
                libelle:
                    '${(a['schedule'] as Map?)?['label'] ?? (a['charge'] as Map?)?['label'] ?? 'Échéance'}',
                montant: nombreOuNull(a['amount']),
              ),
            )
            .toList(),
      );
}

class TransactionPaiementModel extends TransactionPaiement {
  const TransactionPaiementModel({
    required super.id,
    super.reference,
    super.montant,
    super.statut,
    super.mode,
    super.portefeuille,
    super.locataire,
    super.libelleEcheance,
    super.numeroTransaction,
    super.telephonePayeur,
    super.creeLe,
    super.motifRejet,
    super.referencePaiement,
    super.preuve,
    super.checkoutUrl,
  });

  factory TransactionPaiementModel.fromJson(Map<String, dynamic> json) =>
      TransactionPaiementModel(
        id: '${json['id']}',
        reference: json['reference'] as String?,
        montant: nombreOuNull(json['amount']),
        statut: json['status'] as String?,
        mode: json['mode'] as String?,
        portefeuille: json['wallet'] as String?,
        locataire: PersonneResume.depuis(json['tenant']),
        libelleEcheance: (json['schedule'] as Map?)?['label'] as String?,
        numeroTransaction: json['provider_transaction_id'] as String?,
        telephonePayeur: json['payer_phone'] as String?,
        creeLe: json['created_at'] as String?,
        motifRejet: json['rejection_reason'] as String?,
        referencePaiement: (json['payment'] as Map?)?['reference'] as String?,
        preuve: DocumentModel.depuis(json['proof']),
        checkoutUrl: json['checkout_url'] as String?,
      );
}

class RapprochementModel extends Rapprochement {
  const RapprochementModel({
    required super.id,
    super.type,
    super.statut,
    super.montant,
    super.bailId,
    super.locataire,
    super.telephonePayeur,
    super.referenceRecue,
    super.creeLe,
  });

  factory RapprochementModel.fromJson(Map<String, dynamic> json) =>
      RapprochementModel(
        id: '${json['id']}',
        type: json['type'] as String?,
        statut: json['status'] as String?,
        montant: nombreOuNull(json['amount']),
        bailId: json['lease_id']?.toString(),
        locataire: PersonneResume.depuis(json['tenant']),
        telephonePayeur: json['payer_phone'] as String?,
        referenceRecue:
            (json['details'] as Map?)?['reference_recue']?.toString(),
        creeLe: json['created_at'] as String?,
      );
}

class MoyenPaiementModel extends MoyenPaiement {
  const MoyenPaiementModel(
      {required super.fournisseur,
      required super.mode,
      super.libelle,
      super.numeroReception,
      super.actif});

  factory MoyenPaiementModel.fromJson(Map<String, dynamic> json) =>
      MoyenPaiementModel(
        fournisseur: '${json['provider']}',
        mode: '${json['mode']}',
        libelle: json['label'] as String?,
        numeroReception: json['account_number'] as String?,
        actif: json['is_active'] == true,
      );
}
