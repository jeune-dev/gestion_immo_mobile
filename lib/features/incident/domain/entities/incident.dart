import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';

/// Chantier lié à un incident.
class TravauxLies extends Equatable {
  final String id;
  final String? reference;
  final String? titre;
  final String? statut;

  const TravauxLies(
      {required this.id, this.reference, this.titre, this.statut});

  @override
  List<Object?> get props => [id, reference, titre, statut];
}

/// Incident signalé (§ 22) et son traitement (§ 23).
class Incident extends Equatable {
  final String id;
  final String? reference;
  final String? titre;
  final String? description;
  final String? categorie;
  final String? statut;
  final String? immeubleNom;
  final String? appartementNumero;

  /// `null` : signalé par le propriétaire lui-même.
  final PersonneResume? locataire;
  final String? creeLe;
  final String? analyseLe;
  final String? resoluLe;

  /// Note du propriétaire pour le locataire.
  final String? note;
  final String? motifRejet;
  final List<TravauxLies> travaux;

  /// Photos et vidéos jointes par le locataire.
  final List<DocumentApp> pieces;

  bool get ouvert => !['resolu', 'rejete'].contains(statut);

  const Incident({
    required this.id,
    this.reference,
    this.titre,
    this.description,
    this.categorie,
    this.statut,
    this.immeubleNom,
    this.appartementNumero,
    this.locataire,
    this.creeLe,
    this.analyseLe,
    this.resoluLe,
    this.note,
    this.motifRejet,
    this.travaux = const [],
    this.pieces = const [],
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        titre,
        description,
        categorie,
        statut,
        immeubleNom,
        appartementNumero,
        locataire,
        creeLe,
        analyseLe,
        resoluLe,
        note,
        motifRejet,
        travaux,
        pieces,
      ];
}

Incident copieAvecPieces(Incident i, List<DocumentApp> pieces) => Incident(
      id: i.id,
      reference: i.reference,
      titre: i.titre,
      description: i.description,
      categorie: i.categorie,
      statut: i.statut,
      immeubleNom: i.immeubleNom,
      appartementNumero: i.appartementNumero,
      locataire: i.locataire,
      creeLe: i.creeLe,
      analyseLe: i.analyseLe,
      resoluLe: i.resoluLe,
      note: i.note,
      motifRejet: i.motifRejet,
      travaux: i.travaux,
      pieces: pieces,
    );
