import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/documents/data/models/document_model.dart';
import '../../domain/entities/incident.dart';

class IncidentModel extends Incident {
  const IncidentModel({
    required super.id,
    super.reference,
    super.titre,
    super.description,
    super.categorie,
    super.statut,
    super.immeubleNom,
    super.appartementNumero,
    super.locataire,
    super.creeLe,
    super.analyseLe,
    super.resoluLe,
    super.note,
    super.motifRejet,
    super.travaux,
    super.pieces,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
        id: '${json['id']}',
        reference: json['reference'] as String?,
        titre: json['title'] as String?,
        description: json['description'] as String?,
        categorie: json['category'] as String?,
        statut: json['status'] as String?,
        immeubleNom: (json['building'] as Map?)?['name'] as String?,
        appartementNumero: (json['apartment'] as Map?)?['number']?.toString(),
        locataire: PersonneResume.depuis(json['tenant']),
        creeLe: json['created_at'] as String?,
        analyseLe: json['analysed_at'] as String?,
        resoluLe: json['resolved_at'] as String?,
        note: json['owner_note'] as String?,
        motifRejet: json['rejection_reason'] as String?,
        travaux: listeJson(json['work_orders'])
            .map((w) => TravauxLies(
                id: '${w['id']}',
                reference: w['reference'] as String?,
                titre: w['title'] as String?,
                statut: w['status'] as String?))
            .toList(),
        pieces:
            listeJson(json['documents']).map(DocumentModel.fromJson).toList(),
      );
}
