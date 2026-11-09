import 'package:gestion_immo_mobile/core/models/logement_resume.dart';
import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';

import '../../domain/entities/bail.dart';

int? _entierOuNull(dynamic v) => v == null ? null : entier(v);

class BailModel extends Bail {
  const BailModel({
    required super.id,
    super.reference,
    super.statut,
    super.typeBail,
    super.debut,
    super.fin,
    super.sortieLe,
    super.loyer,
    super.charges,
    super.montantCaution,
    super.periodicite,
    super.jourEcheance,
    super.nbOccupants,
    super.preavisMois,
    super.revisionLoyer,
    super.conditionsParticulieres,
    super.locataire,
    super.logement,
    super.caution,
    super.resteDu,
    super.totalEncaisse,
    super.etatsDesLieux,
    super.proposeLe,
    super.accepteLe,
    super.refuseLe,
    super.motifRefus,
    super.modeAccord,
    super.congePar,
    super.sortiePrevue,
    super.motifConge,
    super.avenants,
  });

  factory BailModel.fromJson(Map<String, dynamic> json) {
    final caution = json['deposit'] as Map?;
    final solde = (json['balance'] as Map?) ?? const {};
    return BailModel(
      id: '${json['id']}',
      reference: json['reference'] as String?,
      statut: json['status'] as String?,
      typeBail: json['lease_type'] as String?,
      debut: json['start_date'] as String?,
      fin: json['end_date'] as String?,
      sortieLe: json['ended_on'] as String?,
      loyer: _entierOuNull(json['rent_amount']),
      charges: _entierOuNull(json['charges_amount']),
      montantCaution: _entierOuNull(json['deposit_amount']),
      periodicite: json['periodicity'] as String?,
      jourEcheance: _entierOuNull(json['due_day']),
      nbOccupants: _entierOuNull(json['occupants_count']),
      preavisMois: _entierOuNull(json['notice_period_months']),
      revisionLoyer: json['rent_revision_rule'] as String?,
      conditionsParticulieres: json['special_conditions'] as String?,
      locataire: PersonneResume.depuis(json['tenant']),
      logement: LogementResume.depuis(json['apartment']),
      caution: caution == null
          ? null
          : CautionDuBail(
              id: '${caution['id']}',
              statut: caution['status'] as String?,
              recue: nombreOuNull(caution['amount_received']),
              attendue: nombreOuNull(caution['amount_expected']),
              retenue: nombreOuNull(caution['amount_withheld']),
              restituee: nombreOuNull(caution['amount_refunded']),
            ),
      resteDu: nombreOuNull(solde['reste_du']),
      totalEncaisse: nombreOuNull(solde['total_encaisse']),
      etatsDesLieux: listeJson(json['inspections'])
          .map(
            (i) => EtatDesLieuxDuBail(
              id: '${i['id']}',
              type: i['type'] as String?,
              version: _entierOuNull(i['version']),
              statut: i['status'] as String?,
              date: (i['performed_at'] ?? i['created_at']) as String?,
            ),
          )
          .toList(),
      proposeLe: json['proposed_at'] as String?,
      accepteLe: json['tenant_accepted_at'] as String?,
      refuseLe: json['tenant_refused_at'] as String?,
      motifRefus: json['refusal_reason'] as String?,
      modeAccord: json['acceptance_method'] as String?,
      congePar: json['notice_given_by'] as String?,
      sortiePrevue: json['planned_exit_date'] as String?,
      motifConge: json['notice_reason'] as String?,
      avenants: listeJson(json['amendments']).map(avenantDepuis).toList(),
    );
  }
}

/// Avenant de loyer tel que renvoyé par l'API (fiche du bail, espace locataire).
AvenantLoyer avenantDepuis(Map<String, dynamic> a) => AvenantLoyer(
  id: '${a['id']}',
  statut: '${a['status'] ?? 'propose'}',
  loyerAvant: _entierOuNull(a['previous_rent_amount']) ?? 0,
  chargesAvant: _entierOuNull(a['previous_charges_amount']) ?? 0,
  loyer: _entierOuNull(a['rent_amount']) ?? 0,
  charges: _entierOuNull(a['charges_amount']) ?? 0,
  dateEffet: '${a['effective_from'] ?? ''}',
  motif: a['reason'] as String?,
  motifRefus: a['refusal_reason'] as String?,
  modeAccord: a['acceptance_method'] as String?,
  creeLe: a['created_at'] as String?,
);

class ContratBailModel extends ContratBail {
  const ContratBailModel({
    required super.version,
    required super.documentId,
    super.versionModele,
    super.creeLe,
  });

  factory ContratBailModel.fromJson(Map<String, dynamic> j) => ContratBailModel(
    version: entier(j['version']),
    documentId: '${j['document_id']}',
    versionModele: _entierOuNull(j['template_version']),
    creeLe: j['created_at'] as String?,
  );
}
