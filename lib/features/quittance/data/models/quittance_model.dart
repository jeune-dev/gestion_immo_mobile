import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/quittance.dart';

class QuittanceModel extends Quittance {
  const QuittanceModel(
      {required super.id,
      super.numero,
      super.libelleEcheance,
      super.locataire,
      super.emiseLe,
      super.montant,
      super.annulee});

  factory QuittanceModel.fromJson(Map<String, dynamic> json) => QuittanceModel(
        id: '${json['id']}',
        numero: json['number']?.toString(),
        libelleEcheance: (json['schedule'] as Map?)?['label'] as String?,
        locataire: PersonneResume.depuis(json['tenant']),
        emiseLe: json['issued_at'] as String?,
        montant: nombreOuNull(json['amount']),
        annulee: json['cancelled_at'] != null,
      );
}
