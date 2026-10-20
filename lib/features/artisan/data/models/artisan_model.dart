import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/artisan.dart';

class ArtisanModel extends Artisan {
  const ArtisanModel({
    required super.id,
    required super.nom,
    super.metier,
    super.telephone,
    super.email,
    super.notes,
    super.actif,
    super.interventions,
    super.totalPaye,
  });

  factory ArtisanModel.fromJson(Map<String, dynamic> json) => ArtisanModel(
        id: '${json['id']}',
        nom: json['name'] as String? ?? '',
        metier: json['trade'] as String?,
        telephone: json['phone'] as String?,
        email: json['email'] as String?,
        notes: json['notes'] as String?,
        actif: json['is_active'] != false,
        interventions: entier(json['interventions_count']),
        totalPaye: nombreOuNull(json['total_spent']),
      );
}
