import 'package:gestion_immo_mobile/core/models/logement_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/locataire.dart';

class InvitationModel extends Invitation {
  const InvitationModel({required super.code, super.expireLe});

  /// `null` quand la réponse ne contient pas de code (invitation non demandée).
  static InvitationModel? fromJsonOuNull(dynamic json) {
    if (json is! Map || json['code'] == null) return null;
    return InvitationModel(
      code: json['code'].toString(),
      expireLe: json['expires_at'] as String?,
    );
  }
}

class LocataireModel extends Locataire {
  const LocataireModel({
    required super.id,
    required super.prenom,
    required super.nom,
    super.telephone,
    super.email,
    super.typePiece,
    super.numeroPiece,
    super.notes,
    super.compteActif,
    super.consentementWhatsapp,
    super.logementCourant,
    super.invitationEnvoyee,
    super.baux,
    super.solde,
    super.paiementsRecents,
  });

  factory LocataireModel.fromJson(Map<String, dynamic> json) {
    final solde = json['balance'] as Map? ?? const {};
    final bailCourant = json['current_lease'] as Map?;
    return LocataireModel(
      id: json['id']?.toString() ?? '',
      prenom: json['first_name'] as String? ?? '',
      nom: json['last_name'] as String? ?? '',
      telephone: json['phone'] as String?,
      email: json['email'] as String?,
      typePiece: json['id_document_type'] as String?,
      numeroPiece: json['id_document_number'] as String?,
      notes: json['notes'] as String?,
      compteActif: json['account_active'] == true,
      consentementWhatsapp: json['whatsapp_consent'] == true,
      logementCourant: LogementResume.depuis(bailCourant?['apartment']),
      invitationEnvoyee: json['pending_invitation'] != null,
      baux: listeJson(json['leases'])
          .map(
            (b) => BailDuLocataire(
              id: b['id']?.toString() ?? '',
              reference: b['reference'] as String?,
              statut: b['status'] as String?,
              loyer: nombreOuNull(b['rent_amount']),
              logement: LogementResume.depuis(b['apartment']),
            ),
          )
          .toList(),
      solde: SoldeLocataire(
        resteDu: nombreOuNull(solde['reste_du']),
        impayes: nombreOuNull(solde['impayes']),
        echeancesEnRetard: entier(solde['echeances_en_retard']),
      ),
      paiementsRecents: listeJson(json['recent_payments'])
          .map(
            (p) => PaiementRecent(
              reference: p['reference'] as String?,
              date: p['paid_on'] as String?,
              moyen: p['method'] as String?,
              montant: nombreOuNull(p['amount']),
            ),
          )
          .toList(),
    );
  }
}
