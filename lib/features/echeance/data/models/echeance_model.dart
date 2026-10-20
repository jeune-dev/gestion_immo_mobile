import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/echeance.dart';

class EcheanceModel extends Echeance {
  const EcheanceModel({
    required super.id,
    super.bailId,
    super.libelle,
    super.montantDu,
    super.montantPaye,
    super.dateEcheance,
    super.statut,
    super.locataire,
    super.logementNumero,
  });

  factory EcheanceModel.fromJson(Map<String, dynamic> json) => EcheanceModel(
        id: '${json['id']}',
        bailId: json['lease_id']?.toString(),
        libelle: json['label'] as String?,
        montantDu: entier(json['amount_due']),
        montantPaye: entier(json['amount_paid']),
        dateEcheance: json['due_date'] as String?,
        statut: json['status'] as String?,
        locataire: PersonneResume.depuis(json['tenant']),
        logementNumero: (json['apartment'] as Map?)?['number']?.toString(),
      );
}
