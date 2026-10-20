import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';

/// Photo d'intervention (§ 19), classée avant / pendant / après.
class PhotoTravaux extends Equatable {
  final String id;
  final DocumentApp document;
  const PhotoTravaux({required this.id, required this.document});

  @override
  List<Object?> get props => [id, document];
}

class DepenseDuChantier extends Equatable {
  final String libelle;
  final String? date;
  final num? montant;
  const DepenseDuChantier({required this.libelle, this.date, this.montant});

  @override
  List<Object?> get props => [libelle, date, montant];
}

/// Changement de statut historisé.
class EvenementTravaux extends Equatable {
  final String? statut;
  final String? date;
  final String? commentaire;
  const EvenementTravaux({this.statut, this.date, this.commentaire});

  @override
  List<Object?> get props => [statut, date, commentaire];
}

/// Chantier (§ 18) : statut historisé, photos, dépenses.
class Travaux extends Equatable {
  final String id;
  final String? reference;
  final String? titre;
  final String? description;
  final String? categorie;
  final String? priorite;
  final String? statut;
  final String? immeubleNom;
  final String? appartementId;
  final String? appartementNumero;
  final String? artisanId;
  final String? artisanNom;
  final String? prevuLe;
  final num? coutEstime;
  final num? coutReel;
  final num? totalDepenses;
  final String? incidentReference;

  /// Phase (`avant`, `pendant`, `apres`) → photos.
  final Map<String, List<PhotoTravaux>> photos;
  final List<DepenseDuChantier> depenses;
  final List<EvenementTravaux> historique;

  /// Terminé ou annulé : figé, ses photos sont conservées comme preuves.
  bool get ferme => statut == 'termine' || statut == 'annule';

  const Travaux({
    required this.id,
    this.reference,
    this.titre,
    this.description,
    this.categorie,
    this.priorite,
    this.statut,
    this.immeubleNom,
    this.appartementId,
    this.appartementNumero,
    this.artisanId,
    this.artisanNom,
    this.prevuLe,
    this.coutEstime,
    this.coutReel,
    this.totalDepenses,
    this.incidentReference,
    this.photos = const {},
    this.depenses = const [],
    this.historique = const [],
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        titre,
        description,
        categorie,
        priorite,
        statut,
        immeubleNom,
        appartementId,
        appartementNumero,
        artisanId,
        artisanNom,
        prevuLe,
        coutEstime,
        coutReel,
        totalDepenses,
        incidentReference,
        photos,
        depenses,
        historique,
      ];
}
