import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/entities/quittance.dart';

/// Ligne d'imputation d'un paiement sur une échéance ou une charge.
class Imputation extends Equatable {
  final String libelle;
  final num? montant;
  const Imputation({required this.libelle, this.montant});

  @override
  List<Object?> get props => [libelle, montant];
}

/// Paiement de loyer reçu (§ 12).
class Paiement extends Equatable {
  final String id;
  final String? reference;
  final num? montant;
  final String? statut;
  final PersonneResume? locataire;
  final String? logementNumero;
  final String? moyen;
  final String? payeLe;
  final String? commentaire;
  final String? rembourseLe;
  final String? motifRemboursement;
  final List<Imputation> imputations;

  const Paiement({
    required this.id,
    this.reference,
    this.montant,
    this.statut,
    this.locataire,
    this.logementNumero,
    this.moyen,
    this.payeLe,
    this.commentaire,
    this.rembourseLe,
    this.motifRemboursement,
    this.imputations = const [],
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        montant,
        statut,
        locataire,
        logementNumero,
        moyen,
        payeLe,
        commentaire,
        rembourseLe,
        motifRemboursement,
        imputations,
      ];
}

/// Fiche d'un paiement et ses quittances.
class FichePaiement extends Equatable {
  final Paiement paiement;
  final List<Quittance> quittances;
  const FichePaiement({required this.paiement, required this.quittances});

  @override
  List<Object?> get props => [paiement, quittances];
}

/// Paiement en ligne (Wave, Orange Money via PayDunya) ou paiement direct déclaré avec une preuve (§ 51).
class TransactionPaiement extends Equatable {
  final String id;
  final String? reference;
  final num? montant;
  final String? statut;
  final String? mode;
  final String? portefeuille;
  final PersonneResume? locataire;
  final String? libelleEcheance;
  final String? numeroTransaction;
  final String? telephonePayeur;
  final String? creeLe;
  final String? motifRejet;
  final String? referencePaiement;
  final DocumentApp? preuve;

  /// Page de paiement en ligne (à rouvrir tant que le paiement n'est pas confirmé).
  final String? checkoutUrl;

  /// Preuve déclarée par le locataire, en attente de la validation du propriétaire.
  bool get aValider => mode == 'preuve' && statut == 'en_attente';

  /// Paiement en ligne terminé (confirmé, échoué, annulé…).
  bool get termine => !['initiee', 'en_attente'].contains(statut);

  const TransactionPaiement({
    required this.id,
    this.reference,
    this.montant,
    this.statut,
    this.mode,
    this.portefeuille,
    this.locataire,
    this.libelleEcheance,
    this.numeroTransaction,
    this.telephonePayeur,
    this.creeLe,
    this.motifRejet,
    this.referencePaiement,
    this.preuve,
    this.checkoutUrl,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        montant,
        statut,
        mode,
        portefeuille,
        locataire,
        libelleEcheance,
        numeroTransaction,
        telephonePayeur,
        creeLe,
        motifRejet,
        referencePaiement,
        preuve,
        checkoutUrl,
      ];
}

/// Entrée de la file « À rapprocher » (§ 51.3) : paiement non identifié ou excédent.
class Rapprochement extends Equatable {
  final String id;
  final String? type;
  final String? statut;
  final num? montant;
  final String? bailId;
  final PersonneResume? locataire;
  final String? telephonePayeur;
  final String? referenceRecue;
  final String? creeLe;

  const Rapprochement({
    required this.id,
    this.type,
    this.statut,
    this.montant,
    this.bailId,
    this.locataire,
    this.telephonePayeur,
    this.referenceRecue,
    this.creeLe,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        statut,
        montant,
        bailId,
        locataire,
        telephonePayeur,
        referenceRecue,
        creeLe
      ];
}

/// Moyen de paiement configuré par le propriétaire (§ 51) ; les clés ne sont jamais renvoyées.
class MoyenPaiement extends Equatable {
  final String fournisseur;
  final String mode;
  final String? libelle;
  final String? numeroReception;
  final bool actif;

  const MoyenPaiement(
      {required this.fournisseur,
      required this.mode,
      this.libelle,
      this.numeroReception,
      this.actif = false});

  @override
  List<Object?> get props =>
      [fournisseur, mode, libelle, numeroReception, actif];
}
