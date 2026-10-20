import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/caution.dart';

class CautionModel extends Caution {
  const CautionModel({
    required super.id,
    super.statut,
    super.attendue,
    super.recue,
    super.retenue,
    super.restituee,
    super.solde,
    super.restituerAvant,
    super.bailReference,
    super.bailStatut,
    super.locataire,
    super.mouvements,
  });

  factory CautionModel.fromJson(Map<String, dynamic> json) {
    final bail = json['lease'] as Map?;
    return CautionModel(
      id: '${json['id']}',
      statut: json['status'] as String?,
      attendue: entier(json['amount_expected']),
      recue: entier(json['amount_received']),
      retenue: entier(json['amount_withheld']),
      restituee: entier(json['amount_refunded']),
      solde: entier(json['balance']),
      restituerAvant: json['refund_due_date'] as String?,
      bailReference: bail?['reference'] as String?,
      bailStatut: bail?['status'] as String?,
      locataire: PersonneResume.depuis(json['tenant']),
      mouvements: listeJson(json['transactions'])
          .map(
            (t) => MouvementCaution(
              id: '${t['id']}',
              type: t['type'] as String?,
              motif: t['reason'] as String?,
              date: t['occurred_on'] as String?,
              description: t['description'] as String?,
              montant: nombreOuNull(t['amount']),
              statutContestation: t['contest_status'] as String?,
              messageContestation: t['contest_message'] as String?,
              reponseProprietaire: t['owner_response'] as String?,
            ),
          )
          .toList(),
    );
  }
}
