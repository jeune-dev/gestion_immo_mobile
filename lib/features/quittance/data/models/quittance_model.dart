import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';

import '../../domain/entities/quittance.dart';

class QuittanceModel extends Quittance {
  const QuittanceModel({
    required super.id,
    super.numero,
    super.libelleEcheance,
    super.locataire,
    super.emiseLe,
    super.montant,
    super.annulee,
    super.periodeDebut,
    super.periodeFin,
    super.logementNumero,
    super.immeuble,
    super.referencesPaiement,
  });

  factory QuittanceModel.fromJson(Map<String, dynamic> json) {
    final echeance = json['schedule'] as Map?;
    final logement = echeance?['apartment'] as Map?;
    return QuittanceModel(
      id: '${json['id']}',
      numero: json['number']?.toString(),
      libelleEcheance: echeance?['label'] as String?,
      locataire: PersonneResume.depuis(json['tenant']),
      emiseLe: json['issued_at'] as String?,
      montant: nombreOuNull(json['amount']),
      annulee: json['cancelled_at'] != null,
      periodeDebut: echeance?['period_start'] as String?,
      periodeFin: echeance?['period_end'] as String?,
      logementNumero: logement?['number']?.toString(),
      immeuble: (logement?['building'] as Map?)?['name']?.toString(),
      referencesPaiement: [
        for (final r in (json['payment_references'] as List? ?? const [])) '$r',
      ],
    );
  }
}
