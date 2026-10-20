import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/immeuble.dart';

class ImmeubleModel extends Immeuble {
  const ImmeubleModel({
    required super.id,
    required super.nom,
    super.adresse,
    super.quartier,
    super.ville,
    super.nbEtages,
    super.nbAppartementsPrevus,
    super.description,
    super.nbAppartements,
    super.nbOccupes,
  });

  factory ImmeubleModel.fromJson(Map<String, dynamic> json) => ImmeubleModel(
        id: '${json['id']}',
        nom: json['name'] as String? ?? '',
        adresse: json['address'] as String?,
        quartier: json['district'] as String?,
        ville: json['city'] as String?,
        nbEtages: (json['floors_count'] as num?)?.toInt(),
        nbAppartementsPrevus:
            (json['declared_apartments_count'] as num?)?.toInt(),
        description: json['description'] as String?,
        nbAppartements: entier(json['apartments_count']),
        nbOccupes: entier(json['occupied_count']),
      );
}
