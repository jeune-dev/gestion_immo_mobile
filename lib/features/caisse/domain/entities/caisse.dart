import 'package:equatable/equatable.dart';

/// Mouvement de caisse (§ 21) : loyer encaissé, dépense, autre revenu…
class MouvementCaisse extends Equatable {
  final String id;
  final bool entree;
  final String? libelle;
  final String? date;
  final String? categorie;
  final String? moyen;
  final num? montant;
  final bool annule;

  /// Saisi à la main (seuls ceux-là s'annulent depuis la caisse).
  final bool manuel;

  const MouvementCaisse({
    required this.id,
    this.entree = true,
    this.libelle,
    this.date,
    this.categorie,
    this.moyen,
    this.montant,
    this.annule = false,
    this.manuel = false,
  });

  @override
  List<Object?> get props =>
      [id, entree, libelle, date, categorie, moyen, montant, annule, manuel];
}

class TotalCategorie extends Equatable {
  final String? categorie;
  final num? total;
  const TotalCategorie({this.categorie, this.total});

  @override
  List<Object?> get props => [categorie, total];
}

/// Synthèse de la caisse sur une période.
class SyntheseCaisse extends Equatable {
  final num? entrees;
  final num? sorties;
  final num? solde;
  final List<TotalCategorie> detailEntrees;
  final List<TotalCategorie> detailSorties;

  /// Cautions détenues : hors revenus.
  final num? cautionsDetenues;

  const SyntheseCaisse(
      {this.entrees,
      this.sorties,
      this.solde,
      this.detailEntrees = const [],
      this.detailSorties = const [],
      this.cautionsDetenues});

  @override
  List<Object?> get props =>
      [entrees, sorties, solde, detailEntrees, detailSorties, cautionsDetenues];
}
