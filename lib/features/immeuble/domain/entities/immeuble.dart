import 'package:equatable/equatable.dart';

class Immeuble extends Equatable {
  final String id;
  final String nom;
  final String? adresse;
  final String? quartier;
  final String? ville;
  final int? nbEtages;
  final int? nbAppartementsPrevus;
  final String? description;

  /// Compteurs de la liste (`apartments_count`, `occupied_count`).
  final int nbAppartements;
  final int nbOccupes;

  String get adresseComplete => [adresse, quartier, ville]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(', ');

  const Immeuble({
    required this.id,
    required this.nom,
    this.adresse,
    this.quartier,
    this.ville,
    this.nbEtages,
    this.nbAppartementsPrevus,
    this.description,
    this.nbAppartements = 0,
    this.nbOccupes = 0,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        adresse,
        quartier,
        ville,
        nbEtages,
        nbAppartementsPrevus,
        description,
        nbAppartements,
        nbOccupes
      ];
}
