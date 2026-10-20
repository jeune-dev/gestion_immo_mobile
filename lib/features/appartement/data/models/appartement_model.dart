import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/appartement.dart';

class AppartementModel extends Appartement {
  const AppartementModel({
    required super.id,
    required super.numero,
    super.type,
    super.etage,
    super.surface,
    super.nbPieces,
    super.loyer,
    super.charges,
    super.coefficientCharges,
    super.meuble,
    super.description,
    super.statut,
    super.immeubleId,
    super.immeubleNom,
    super.bailCourant,
    super.locataireCourant,
    super.historique,
  });

  static OccupationAppartement _occupation(Map<String, dynamic> j) =>
      OccupationAppartement(
        bailId: '${j['id']}',
        reference: j['reference'] as String?,
        statut: j['status'] as String?,
        debut: j['start_date'] as String?,
        fin: (j['ended_on'] ?? j['end_date']) as String?,
        locataire: PersonneResume.depuis(j['tenant']),
      );

  factory AppartementModel.fromJson(Map<String, dynamic> json) {
    final immeuble = json['building'] as Map?;
    final bail = json['current_lease'];
    return AppartementModel(
      id: '${json['id']}',
      numero: '${json['number'] ?? ''}',
      type: json['type'] as String?,
      etage: (json['floor'] as num?)?.toInt(),
      surface: nombreOuNull(json['surface']),
      nbPieces: (json['rooms_count'] as num?)?.toInt(),
      loyer: json['rent_amount'] == null ? null : entier(json['rent_amount']),
      charges: json['charges_amount'] == null
          ? null
          : entier(json['charges_amount']),
      coefficientCharges: nombreOuNull(json['charge_coefficient']),
      meuble: json['is_furnished'] == true,
      description: json['description'] as String?,
      statut: json['status'] as String?,
      immeubleId: (immeuble?['id'] ?? json['building_id'])?.toString(),
      immeubleNom: immeuble?['name'] as String?,
      bailCourant:
          bail is Map ? _occupation(Map<String, dynamic>.from(bail)) : null,
      locataireCourant: PersonneResume.depuis(json['current_tenant']),
      historique: listeJson(json['tenant_history']).map(_occupation).toList(),
    );
  }
}

class RentabiliteAppartementModel extends RentabiliteAppartement {
  const RentabiliteAppartementModel(
      {super.loyersEncaisses,
      super.chargesRecuperees,
      super.depenses,
      super.resultatNet,
      super.impayes});

  factory RentabiliteAppartementModel.fromJson(Map<String, dynamic> j) =>
      RentabiliteAppartementModel(
        loyersEncaisses: nombreOuNull(j['loyers_encaisses']),
        chargesRecuperees: nombreOuNull(j['charges_recuperees']),
        depenses: nombreOuNull(j['depenses']),
        resultatNet: nombreOuNull(j['resultat_net']),
        impayes: nombreOuNull(j['impayes']),
      );
}

class EvenementAppartementModel extends EvenementAppartement {
  const EvenementAppartementModel(
      {required super.libelle, super.date, super.montant});

  factory EvenementAppartementModel.fromJson(Map<String, dynamic> j) =>
      EvenementAppartementModel(
          libelle: '${j['libelle'] ?? ''}',
          date: j['date'] as String?,
          montant: nombreOuNull(j['montant']));
}
