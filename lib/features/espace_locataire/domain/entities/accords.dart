import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';

/// Bail proposé par le bailleur, en attente de la réponse du locataire.
class BailPropose extends Equatable {
  final String id;
  final String? reference;
  final String? typeBail;
  final String? debut;
  final String? fin;
  final int loyer;
  final int charges;
  final int caution;
  final String? periodicite;
  final int? jourEcheance;
  final int? preavisMois;
  final String? conditionsParticulieres;
  final String? revisionLoyer;
  final String logement;
  final String? adresse;
  final String? bailleur;
  final String? contratDocumentId;
  final String? immeubleId;
  final String? couvertureId;

  const BailPropose({
    required this.id,
    required this.loyer,
    required this.charges,
    required this.caution,
    required this.logement,
    this.reference,
    this.typeBail,
    this.debut,
    this.fin,
    this.periodicite,
    this.jourEcheance,
    this.preavisMois,
    this.conditionsParticulieres,
    this.revisionLoyer,
    this.adresse,
    this.bailleur,
    this.contratDocumentId,
    this.immeubleId,
    this.couvertureId,
  });

  @override
  List<Object?> get props => [id, reference, loyer, charges, debut];
}

/// Nouveau loyer proposé sur un bail en cours.
class AvenantPropose extends Equatable {
  final AvenantLoyer avenant;
  final String? bailReference;
  final String logement;
  const AvenantPropose({
    required this.avenant,
    required this.logement,
    this.bailReference,
  });

  @override
  List<Object?> get props => [avenant, bailReference];
}

/// Ce qui attend la réponse du locataire.
class AccordsLocataire extends Equatable {
  final List<BailPropose> baux;
  final List<AvenantPropose> avenants;
  const AccordsLocataire({this.baux = const [], this.avenants = const []});

  bool get vide => baux.isEmpty && avenants.isEmpty;
  int get nombre => baux.length + avenants.length;

  @override
  List<Object?> get props => [baux, avenants];
}
