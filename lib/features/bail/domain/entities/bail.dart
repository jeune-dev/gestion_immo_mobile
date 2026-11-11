import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/logement_resume.dart';
import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Caution du bail (§ 55), telle qu'affichée sur sa fiche.
class CautionDuBail extends Equatable {
  final String id;
  final String? statut;
  final num? recue;
  final num? attendue;
  final num? retenue;
  final num? restituee;

  const CautionDuBail({
    required this.id,
    this.statut,
    this.recue,
    this.attendue,
    this.retenue,
    this.restituee,
  });

  @override
  List<Object?> get props => [id, statut, recue, attendue, retenue, restituee];
}

/// État des lieux rattaché au bail.
class EtatDesLieuxDuBail extends Equatable {
  final String id;
  final String? type;
  final int? version;
  final String? statut;
  final String? date;

  const EtatDesLieuxDuBail({
    required this.id,
    this.type,
    this.version,
    this.statut,
    this.date,
  });

  @override
  List<Object?> get props => [id, type, version, statut, date];
}

/// Contrat de bail généré (PDF), à partir du modèle publié (§ 53).
class ContratBail extends Equatable {
  final int version;
  final String documentId;
  final int? versionModele;
  final String? creeLe;

  const ContratBail({
    required this.version,
    required this.documentId,
    this.versionModele,
    this.creeLe,
  });

  @override
  List<Object?> get props => [version, documentId, versionModele, creeLe];
}

/// Nouveau loyer proposé au locataire : appliqué seulement après son accord.
class AvenantLoyer extends Equatable {
  final String id;
  final String statut;
  final int loyerAvant;
  final int chargesAvant;
  final int loyer;
  final int charges;
  final String dateEffet;
  final String? motif;
  final String? motifRefus;
  final String? modeAccord;
  final String? creeLe;

  const AvenantLoyer({
    required this.id,
    required this.statut,
    required this.loyerAvant,
    required this.chargesAvant,
    required this.loyer,
    required this.charges,
    required this.dateEffet,
    this.motif,
    this.motifRefus,
    this.modeAccord,
    this.creeLe,
  });

  bool get enAttente => statut == 'propose';
  int get totalAvant => loyerAvant + chargesAvant;
  int get total => loyer + charges;

  @override
  List<Object?> get props => [
    id,
    statut,
    loyer,
    charges,
    dateEffet,
    motifRefus,
  ];
}

/// Contrat de location (§ 10) et son cycle : brouillon → actif → terminé → clos.
class Bail extends Equatable {
  final String id;
  final String? reference;
  final String? statut;
  final String? typeBail;
  final String? debut;
  final String? fin;
  final String? sortieLe;
  final int? loyer;
  final int? charges;
  final int? montantCaution;
  final String? periodicite;
  final int? jourEcheance;
  final int? nbOccupants;
  final int? preavisMois;
  final String? revisionLoyer;
  final String? conditionsParticulieres;
  final PersonneResume? locataire;
  final LogementResume? logement;
  final CautionDuBail? caution;
  final num? resteDu;
  final num? totalEncaisse;
  final List<EtatDesLieuxDuBail> etatsDesLieux;

  /// Accord du locataire sur le brouillon (application ou bail signé joint).
  final String? proposeLe;
  final String? accepteLe;
  final String? refuseLe;
  final String? motifRefus;
  final String? modeAccord;

  /// Congé : qui l'a donné et pour quand.
  final String? congePar;
  final String? sortiePrevue;
  final String? motifConge;
  final List<AvenantLoyer> avenants;

  const Bail({
    required this.id,
    this.reference,
    this.statut,
    this.typeBail,
    this.debut,
    this.fin,
    this.sortieLe,
    this.loyer,
    this.charges,
    this.montantCaution,
    this.periodicite,
    this.jourEcheance,
    this.nbOccupants,
    this.preavisMois,
    this.revisionLoyer,
    this.conditionsParticulieres,
    this.locataire,
    this.logement,
    this.caution,
    this.resteDu,
    this.totalEncaisse,
    this.etatsDesLieux = const [],
    this.proposeLe,
    this.accepteLe,
    this.refuseLe,
    this.motifRefus,
    this.modeAccord,
    this.congePar,
    this.sortiePrevue,
    this.motifConge,
    this.avenants = const [],
  });

  AvenantLoyer? get avenantEnAttente =>
      avenants.where((a) => a.enAttente).firstOrNull;

  @override
  List<Object?> get props => [
    id,
    reference,
    statut,
    typeBail,
    debut,
    fin,
    sortieLe,
    loyer,
    charges,
    montantCaution,
    periodicite,
    jourEcheance,
    nbOccupants,
    preavisMois,
    revisionLoyer,
    conditionsParticulieres,
    locataire,
    logement,
    caution,
    resteDu,
    totalEncaisse,
    etatsDesLieux,
    proposeLe,
    accepteLe,
    refuseLe,
    congePar,
    sortiePrevue,
    avenants,
  ];
}

/// Fiche du bail : le bail et ses contrats générés.
class FicheBail extends Equatable {
  final Bail bail;
  final List<ContratBail> contrats;
  const FicheBail({required this.bail, required this.contrats});

  @override
  List<Object?> get props => [bail, contrats];
}
