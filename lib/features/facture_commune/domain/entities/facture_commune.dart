import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Part d'un appartement dans la répartition d'une facture (§ 17).
class LigneRepartition extends Equatable {
  final String? logementNumero;
  final PersonneResume? locataire;
  final String? explication;
  final num? montant;

  const LigneRepartition({
    this.logementNumero,
    this.locataire,
    this.explication,
    this.montant,
  });

  @override
  List<Object?> get props => [logementNumero, locataire, explication, montant];
}

/// Facture commune (§ 16) : eau, électricité, gardiennage…
class FactureCommune extends Equatable {
  final String id;
  final String? typeCharge;
  final String? immeubleId;
  final String? immeubleNom;
  final String? fournisseur;
  final String? numeroFacture;
  final num? montant;
  final String? debutPeriode;
  final String? finPeriode;
  final String? dateLimite;
  final String? methodeRepartition;
  final bool refacturer;
  final String? notes;
  final String? statut;
  final List<LigneRepartition> repartition;

  bool get brouillon => statut == 'brouillon';

  /// Répartition saisie ligne par ligne (consommation, montant personnalisé).
  bool get parLigne =>
      methodeRepartition == 'consommation' ||
      methodeRepartition == 'personnalise';

  const FactureCommune({
    required this.id,
    this.typeCharge,
    this.immeubleId,
    this.immeubleNom,
    this.fournisseur,
    this.numeroFacture,
    this.montant,
    this.debutPeriode,
    this.finPeriode,
    this.dateLimite,
    this.methodeRepartition,
    this.refacturer = false,
    this.notes,
    this.statut,
    this.repartition = const [],
  });

  @override
  List<Object?> get props => [
    id,
    typeCharge,
    immeubleId,
    immeubleNom,
    fournisseur,
    numeroFacture,
    montant,
    debutPeriode,
    finPeriode,
    dateLimite,
    methodeRepartition,
    refacturer,
    notes,
    statut,
    repartition,
  ];
}

/// Aperçu calculé par l'API avant validation de la répartition.
class ApercuRepartition extends Equatable {
  final List<LigneRepartition> lignes;
  final num? totalRefacture;

  /// Part déjà couverte par les provisions de charges appelées sur la période.
  final num? provisionsDeduites;
  final num? partProprietaire;
  const ApercuRepartition({
    required this.lignes,
    this.totalRefacture,
    this.provisionsDeduites,
    this.partProprietaire,
  });

  @override
  List<Object?> get props => [
    lignes,
    totalRefacture,
    provisionsDeduites,
    partProprietaire,
  ];
}

/// Factures en brouillon à répartir (bandeau de la liste).
class FacturesARepartir extends Equatable {
  final int nombre;
  final num? total;
  const FacturesARepartir({this.nombre = 0, this.total});

  @override
  List<Object?> get props => [nombre, total];
}

/// Charge refacturée à un locataire (§ 15).
class ChargeRefacturee extends Equatable {
  final String id;
  final String? libelle;
  final String? typeCharge;
  final PersonneResume? locataire;
  final String? logementNumero;
  final String? dateEcheance;
  final int montant;
  final int montantPaye;
  final String? statut;

  /// Calcul de la quote-part (détail locataire uniquement, § 28).
  final CalculCharge? calcul;

  int get reste => montant - montantPaye;
  bool get payable =>
      ['a_payer', 'partiellement_paye', 'en_retard'].contains(statut);

  const ChargeRefacturee({
    required this.id,
    this.libelle,
    this.typeCharge,
    this.locataire,
    this.logementNumero,
    this.dateEcheance,
    this.montant = 0,
    this.montantPaye = 0,
    this.statut,
    this.calcul,
  });

  @override
  List<Object?> get props => [
    id,
    libelle,
    typeCharge,
    locataire,
    logementNumero,
    dateEcheance,
    montant,
    montantPaye,
    statut,
    calcul,
  ];
}

/// Explication de la part d'un locataire dans une facture commune : méthode,
/// total de la facture, base de calcul — jamais la part d'un autre logement.
class CalculCharge extends Equatable {
  final String? methode;
  final String? methodeLibelle;
  final int totalFacture;
  final int nbAppartements;
  final String? fournisseur;
  final String? numeroFacture;
  final String? periodeDebut;
  final String? periodeFin;
  final String? explication;

  /// Provision sur charges déjà versée, déduite de la part (propriétaire).
  final int provisionDeduite;

  const CalculCharge({
    this.methode,
    this.methodeLibelle,
    this.totalFacture = 0,
    this.nbAppartements = 0,
    this.fournisseur,
    this.numeroFacture,
    this.periodeDebut,
    this.periodeFin,
    this.explication,
    this.provisionDeduite = 0,
  });

  @override
  List<Object?> get props => [
    methode,
    methodeLibelle,
    totalFacture,
    nbAppartements,
    fournisseur,
    numeroFacture,
    periodeDebut,
    periodeFin,
    explication,
    provisionDeduite,
  ];
}
