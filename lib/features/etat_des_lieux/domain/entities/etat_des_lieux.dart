import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';

class PhotoEdl extends Equatable {
  final String id;
  final DocumentApp document;
  const PhotoEdl({required this.id, required this.document});

  @override
  List<Object?> get props => [id, document];
}

/// Élément d'une pièce (murs, sols, mobilier…) et son état constaté.
class ElementEdl extends Equatable {
  final String id;
  final String? element;
  final String? precision;
  final String? etat;
  final String? commentaire;
  final List<PhotoEdl> photos;

  const ElementEdl(
      {required this.id,
      this.element,
      this.precision,
      this.etat,
      this.commentaire,
      this.photos = const []});

  @override
  List<Object?> get props =>
      [id, element, precision, etat, commentaire, photos];
}

class PieceEdl extends Equatable {
  final String id;
  final String nom;
  final List<ElementEdl> elements;
  const PieceEdl(
      {required this.id, required this.nom, this.elements = const []});

  @override
  List<Object?> get props => [id, nom, elements];
}

/// État des lieux (§ 52) : brouillon → soumis → accepté / contesté → remplacé.
class EtatDesLieux extends Equatable {
  final String id;
  final String? type;
  final int? version;
  final String? statut;
  final String? realiseLe;
  final String? soumisLe;
  final String? creeLe;
  final String? limiteReponse;
  final bool accepteTacitement;

  /// Commentaire du locataire qui conteste.
  final String? contestation;
  final num? compteurEau;
  final num? compteurElectricite;
  final int? nbCles;
  final String? detailCles;
  final String? observations;
  final PersonneResume? locataire;
  final String? appartementNumero;
  final List<PieceEdl> pieces;

  bool get modifiable => statut == 'brouillon';
  String? get date => realiseLe ?? creeLe;

  const EtatDesLieux({
    required this.id,
    this.type,
    this.version,
    this.statut,
    this.realiseLe,
    this.soumisLe,
    this.creeLe,
    this.limiteReponse,
    this.accepteTacitement = false,
    this.contestation,
    this.compteurEau,
    this.compteurElectricite,
    this.nbCles,
    this.detailCles,
    this.observations,
    this.locataire,
    this.appartementNumero,
    this.pieces = const [],
  });

  @override
  List<Object?> get props => [
        id,
        type,
        version,
        statut,
        realiseLe,
        soumisLe,
        creeLe,
        limiteReponse,
        accepteTacitement,
        contestation,
        compteurEau,
        compteurElectricite,
        nbCles,
        detailCles,
        observations,
        locataire,
        appartementNumero,
        pieces,
      ];
}

/// Écart entre l'entrée et la sortie pour un élément.
class EcartEdl extends Equatable {
  final String? piece;
  final String? element;
  final String? etatEntree;
  final String? etatSortie;
  final String? commentaireSortie;

  const EcartEdl(
      {this.piece,
      this.element,
      this.etatEntree,
      this.etatSortie,
      this.commentaireSortie});

  @override
  List<Object?> get props =>
      [piece, element, etatEntree, etatSortie, commentaireSortie];
}

/// Comparaison entrée / sortie (§ 52.3) : éléments dégradés, absents, nouveaux.
class ComparaisonEdl extends Equatable {
  final int elementsSortie;
  final int identiques;
  final int degrades;
  final int ameliores;
  final int absents;
  final List<EcartEdl> ecarts;

  const ComparaisonEdl({
    this.elementsSortie = 0,
    this.identiques = 0,
    this.degrades = 0,
    this.ameliores = 0,
    this.absents = 0,
    this.ecarts = const [],
  });

  @override
  List<Object?> get props =>
      [elementsSortie, identiques, degrades, ameliores, absents, ecarts];
}
