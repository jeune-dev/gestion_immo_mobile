import 'package:equatable/equatable.dart';

/// Dépense (§ 20). Une dépense en espèces est aussi enregistrée dans la caisse.
class Depense extends Equatable {
  final String id;
  final num? montant;
  final String? moyen;
  final String? dateDepense;
  final String? description;
  final String? statut;
  final String? categorieId;
  final String? categorieNom;
  final String? immeubleId;
  final String? immeubleNom;
  final String? appartementId;
  final String? appartementNumero;
  final String? artisanId;
  final String? artisanNom;
  final String? travauxTitre;
  final String? motifAnnulation;

  bool get valide => statut == 'valide';

  const Depense({
    required this.id,
    this.montant,
    this.moyen,
    this.dateDepense,
    this.description,
    this.statut,
    this.categorieId,
    this.categorieNom,
    this.immeubleId,
    this.immeubleNom,
    this.appartementId,
    this.appartementNumero,
    this.artisanId,
    this.artisanNom,
    this.travauxTitre,
    this.motifAnnulation,
  });

  @override
  List<Object?> get props => [
        id,
        montant,
        moyen,
        dateDepense,
        description,
        statut,
        categorieId,
        categorieNom,
        immeubleId,
        immeubleNom,
        appartementId,
        appartementNumero,
        artisanId,
        artisanNom,
        travauxTitre,
        motifAnnulation,
      ];
}

/// Catégorie de dépense : catalogue commun ou propre au propriétaire.
class CategorieDepense extends Equatable {
  final String id;
  final String nom;
  final String? groupeCaisse;
  final bool active;

  /// Catégorie du catalogue commun : ni modifiable ni désactivable.
  final bool catalogue;

  const CategorieDepense(
      {required this.id,
      required this.nom,
      this.groupeCaisse,
      this.active = true,
      this.catalogue = false});

  @override
  List<Object?> get props => [id, nom, groupeCaisse, active, catalogue];
}
