import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/bail/data/models/bail_model.dart';

import '../../domain/entities/accords.dart';

String _logement(Map<String, dynamic>? appartement) {
  if (appartement == null) return 'Logement';
  final immeuble = appartement['building'] as Map?;
  final numero = appartement['number'];
  return [
    if (immeuble?['name'] != null) '${immeuble!['name']}',
    if (numero != null) 'appartement $numero',
  ].join(' · ');
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

AccordsLocataire accordsDepuis(Map<String, dynamic> json) {
  final baux = listeJson(json['leases']).map((l) {
    final appartement = _map(l['apartment']);
    final immeuble = _map(appartement?['building']);
    final bailleur = _map(l['owner']);
    return BailPropose(
      id: '${l['id']}',
      reference: l['reference'] as String?,
      typeBail: l['lease_type'] as String?,
      debut: l['start_date'] as String?,
      fin: l['end_date'] as String?,
      loyer: entier(l['rent_amount']),
      charges: entier(l['charges_amount']),
      caution: entier(l['deposit_amount']),
      periodicite: l['periodicity'] as String?,
      jourEcheance: l['due_day'] == null ? null : entier(l['due_day']),
      preavisMois: l['notice_period_months'] == null
          ? null
          : entier(l['notice_period_months']),
      conditionsParticulieres: l['special_conditions'] as String?,
      revisionLoyer: l['rent_revision_rule'] as String?,
      logement: _logement(appartement),
      adresse: [
        immeuble?['address'],
        immeuble?['district'],
        immeuble?['city'],
      ].where((v) => v != null && '$v'.isNotEmpty).join(', '),
      bailleur:
          (bailleur?['company_name'] ?? bailleur?['display_name']) as String?,
      contratDocumentId: l['contract_document_id'] as String?,
      immeubleId: immeuble?['id'] as String?,
      couvertureId: immeuble?['cover_document_id'] as String?,
    );
  }).toList();
  final avenants = listeJson(json['amendments']).map((a) {
    final bail = _map(a['lease']);
    return AvenantPropose(
      avenant: avenantDepuis(a),
      bailReference: bail?['reference'] as String?,
      logement: _logement(_map(bail?['apartment'])),
    );
  }).toList();
  return AccordsLocataire(baux: baux, avenants: avenants);
}
