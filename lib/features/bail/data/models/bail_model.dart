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
    );
  }
}

class ContratBailModel extends ContratBail {
  const ContratBailModel(
      {required super.version,
      required super.documentId,
      super.versionModele,
      super.creeLe});

  factory ContratBailModel.fromJson(Map<String, dynamic> j) => ContratBailModel(
        version: entier(j['version']),
        documentId: '${j['document_id']}',
        versionModele: _entierOuNull(j['template_version']),
        creeLe: j['created_at'] as String?,
      );
}
