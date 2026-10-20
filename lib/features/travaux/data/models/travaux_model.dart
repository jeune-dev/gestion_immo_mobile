import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/documents/data/models/document_model.dart';
import '../../domain/entities/travaux.dart';

class TravauxModel extends Travaux {
  const TravauxModel({
    required super.id,
    super.reference,
    super.titre,
    super.description,
    super.categorie,
    super.priorite,
    super.statut,
    super.immeubleNom,
    super.appartementId,
    super.appartementNumero,
    super.artisanId,
    super.artisanNom,
    super.prevuLe,
    super.coutEstime,
    super.coutReel,
    super.totalDepenses,
    super.incidentReference,
    super.photos,
    super.depenses,
    super.historique,
  });

  factory TravauxModel.fromJson(Map<String, dynamic> json) {
    final appartement = json['apartment'] as Map?;
    final artisan = json['contractor'] as Map?;
    final photos = (json['photos'] as Map?) ?? const {};
    return TravauxModel(
      id: '${json['id']}',
      reference: json['reference'] as String?,
      titre: json['title'] as String?,
      description: json['description'] as String?,
      categorie: json['category'] as String?,
      priorite: json['priority'] as String?,
      statut: json['status'] as String?,
      immeubleNom: (json['building'] as Map?)?['name'] as String?,
      appartementId: (json['apartment_id'] ?? appartement?['id'])?.toString(),
      appartementNumero: appartement?['number']?.toString(),
      artisanId: (json['contractor_id'] ?? artisan?['id'])?.toString(),
      artisanNom: artisan?['name'] as String?,
      prevuLe: json['scheduled_for'] as String?,
      coutEstime: nombreOuNull(json['estimated_amount']),
      coutReel: nombreOuNull(json['actual_amount']),
      totalDepenses: nombreOuNull(json['total_expenses']),
      incidentReference: (json['incident'] as Map?)?['reference'] as String?,
      photos: {
        for (final phase in ['avant', 'pendant', 'apres'])
          phase: listeJson(photos[phase])
              .where((p) => p['document'] is Map)
              .map((p) => PhotoTravaux(
                  id: '${p['id']}',
                  document: DocumentModel.fromJson(
                      Map<String, dynamic>.from(p['document'] as Map))))
              .toList(),
      },
      depenses: listeJson(json['expenses'])
          .map(
            (d) => DepenseDuChantier(
              libelle:
                  '${d['description'] ?? (d['category'] as Map?)?['name'] ?? 'Dépense'}',
              date: d['spent_on'] as String?,
              montant: nombreOuNull(d['amount']),
            ),
          )
          .toList(),
      historique: listeJson(json['events'])
          .map((e) => EvenementTravaux(
              statut: e['to_status'] as String?,
              date: e['created_at'] as String?,
              commentaire: e['comment'] as String?))
          .toList(),
    );
  }
}
