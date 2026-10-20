import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Bail en cours ou passé, vu depuis l'appartement.
class OccupationAppartement extends Equatable {
  final String bailId;
  final String? reference;
  final String? statut;
  final String? debut;
  final String? fin;
  final PersonneResume? locataire;

  const OccupationAppartement(
      {required this.bailId,
      this.reference,
      this.statut,
      this.debut,
      this.fin,
      this.locataire});

  @override
  List<Object?> get props => [bailId, reference, statut, debut, fin, locataire];
}

class Appartement extends Equatable {
  final String id;
  final String numero;
  final String? type;
  final int? etage;
  final num? surface;
  final int? nbPieces;
  final int? loyer;
  final int? charges;
  final num? coefficientCharges;
  final bool meuble;
  final String? description;
  final String? statut;
  final String? immeubleId;
  final String? immeubleNom;
  final OccupationAppartement? bailCourant;
  final PersonneResume? locataireCourant;

  /// Baux successifs (§ 25).
  final List<OccupationAppartement> historique;

  bool get occupe => statut == 'occupe';

  const Appartement({
    required this.id,
    required this.numero,
    this.type,
    this.etage,
    this.surface,
    this.nbPieces,
    this.loyer,
    this.charges,
    this.coefficientCharges,
    this.meuble = false,
    this.description,
    this.statut,
    this.immeubleId,
    this.immeubleNom,
    this.bailCourant,
    this.locataireCourant,
    this.historique = const [],
  });

  @override
  List<Object?> get props => [
        id,
        numero,
        type,
        etage,
        surface,
        nbPieces,
        loyer,
        charges,
        coefficientCharges,
        meuble,
        description,
        statut,
        immeubleId,
        immeubleNom,
        bailCourant,
        locataireCourant,
        historique,
      ];
}

/// Rentabilité sur une période (§ 25).
class RentabiliteAppartement extends Equatable {
  final num? loyersEncaisses;
  final num? chargesRecuperees;
  final num? depenses;
  final num? resultatNet;
  final num? impayes;

  const RentabiliteAppartement(
      {this.loyersEncaisses,
      this.chargesRecuperees,
      this.depenses,
      this.resultatNet,
      this.impayes});

  @override
  List<Object?> get props =>
      [loyersEncaisses, chargesRecuperees, depenses, resultatNet, impayes];
}

/// Événement de l'historique : bail, paiement, travaux, dépense, incident.
class EvenementAppartement extends Equatable {
  final String libelle;
  final String? date;
  final num? montant;
  const EvenementAppartement({required this.libelle, this.date, this.montant});

  @override
  List<Object?> get props => [libelle, date, montant];
}

/// Tout ce qu'affiche la fiche d'un appartement.
class FicheAppartement extends Equatable {
  final Appartement appartement;
  final RentabiliteAppartement rentabilite;
  final List<EvenementAppartement> historique;
  const FicheAppartement(
      {required this.appartement,
      required this.rentabilite,
      required this.historique});

  @override
  List<Object?> get props => [appartement, rentabilite, historique];
}
