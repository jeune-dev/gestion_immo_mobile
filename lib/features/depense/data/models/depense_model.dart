import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/depense.dart';

class DepenseModel extends Depense {
  const DepenseModel({
    required super.id,
    super.montant,
    super.moyen,
    super.dateDepense,
    super.description,
    super.statut,
    super.categorieId,
    super.categorieNom,
    super.immeubleId,
    super.immeubleNom,
    super.appartementId,
    super.appartementNumero,
    super.artisanId,
    super.artisanNom,
    super.travauxTitre,
    super.motifAnnulation,
  });

  factory DepenseModel.fromJson(Map<String, dynamic> json) {
    final categorie = json['category'] as Map?;
    final immeuble = json['building'] as Map?;
    final appartement = json['apartment'] as Map?;
    final artisan = json['contractor'] as Map?;
    return DepenseModel(
      id: '${json['id']}',
      montant: nombreOuNull(json['amount']),
      moyen: json['method'] as String?,
      dateDepense: json['spent_on'] as String?,
      description: json['description'] as String?,
      statut: json['status'] as String?,
      categorieId: (json['category_id'] ?? categorie?['id'])?.toString(),
      categorieNom: categorie?['name'] as String?,
      immeubleId: (json['building_id'] ?? immeuble?['id'])?.toString(),
      immeubleNom: immeuble?['name'] as String?,
      appartementId: (json['apartment_id'] ?? appartement?['id'])?.toString(),
      appartementNumero: appartement?['number']?.toString(),
      artisanId: (json['contractor_id'] ?? artisan?['id'])?.toString(),
      artisanNom: artisan?['name'] as String?,
      travauxTitre: ((json['workOrder'] ?? json['work_order'])
          as Map?)?['title'] as String?,
      motifAnnulation: json['cancel_reason'] as String?,
    );
  }
}

class CategorieDepenseModel extends CategorieDepense {
  const CategorieDepenseModel(
      {required super.id,
      required super.nom,
      super.groupeCaisse,
      super.active,
      super.catalogue});

  factory CategorieDepenseModel.fromJson(Map<String, dynamic> json) =>
      CategorieDepenseModel(
        id: '${json['id']}',
        nom: json['name'] as String? ?? '',
        groupeCaisse: json['cash_group'] as String?,
        active: json['is_active'] == true,
        catalogue: json['owner_id'] == null,
      );
}
