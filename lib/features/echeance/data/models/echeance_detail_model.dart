import 'package:gestion_immo_mobile/core/utils/format.dart';

import '../../domain/entities/echeance_detail.dart';
import 'echeance_model.dart';

/// Réponse de `GET /echeances/:id` (propriétaire) ou
/// `GET /locataire/echeances/:id` (locataire, sans fiche locataire ni logement).
class EcheanceDetailModel extends EcheanceDetail {
  const EcheanceDetailModel({
    required super.echeance,
    super.periodeDebut,
    super.periodeFin,
    super.loyer,
    super.charges,
    super.immeuble,
    super.payeeLe,
    super.imputations,
    super.quittance,
  });

  factory EcheanceDetailModel.fromJson(Map<String, dynamic> json) {
    final immeuble =
        ((json['apartment'] as Map?)?['building'] as Map?)?['name'];
    final quittance = json['receipt'] as Map?;
    return EcheanceDetailModel(
      echeance: EcheanceModel.fromJson(json),
      periodeDebut: json['period_start'] as String?,
      periodeFin: json['period_end'] as String?,
      loyer: json['rent_amount'] == null ? null : entier(json['rent_amount']),
      charges: json['charges_amount'] == null
          ? null
          : entier(json['charges_amount']),
      immeuble: immeuble?.toString(),
      payeeLe: json['paid_at'] as String?,
      imputations: [
        for (final a in (json['allocations'] as List? ?? const []))
          if (a is Map) _imputation(a),
      ]..sort((a, b) => (b.imputeLe ?? '').compareTo(a.imputeLe ?? '')),
      quittance: quittance == null || quittance['id'] == null
          ? null
          : QuittanceEmise(
              id: '${quittance['id']}',
              numero: quittance['number']?.toString(),
              emiseLe: quittance['issued_at'] as String?,
            ),
    );
  }

  static ImputationPaiement _imputation(Map<dynamic, dynamic> a) {
    final p = a['payment'] as Map?;
    return ImputationPaiement(
      montant: entier(a['amount']),
      imputeLe: a['created_at'] as String?,
      payeLe: p?['paid_on'] as String?,
      reference: p?['reference'] as String?,
      moyen: p?['method'] as String?,
    );
  }
}
