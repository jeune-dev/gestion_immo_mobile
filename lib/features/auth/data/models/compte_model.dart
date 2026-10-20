import 'package:gestion_immo_mobile/core/config/user_role.dart';
import '../../domain/entities/compte.dart';
import '../../domain/entities/droits_abonnement.dart';
import '../../domain/entities/espace_proprietaire.dart';
import '../../domain/entities/utilisateur.dart';

class UtilisateurModel extends Utilisateur {
  const UtilisateurModel({
    required super.id,
    required super.role,
    required super.prenom,
    required super.nom,
    super.email,
    super.telephone,
    super.langue,
    super.doitChangerMotDePasse,
    super.doubleAuthentificationActive,
  });

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) =>
      UtilisateurModel(
        id: '${json['id']}',
        role: UserRole.depuis((json['role_code'] ?? json['role']) as String?),
        prenom: json['first_name'] as String? ?? '',
        nom: json['last_name'] as String? ?? '',
        email: json['email'] as String?,
        telephone: json['phone'] as String?,
        langue: json['language'] as String? ?? 'fr',
        doitChangerMotDePasse: json['must_change_password'] == true,
        doubleAuthentificationActive:
            json['totp_enabled_at'] != null || json['mfa_active'] == true,
      );
}

class EspaceProprietaireModel extends EspaceProprietaire {
  const EspaceProprietaireModel(
      {required super.id,
      required super.nomAffiche,
      super.societe,
      super.ville,
      super.statut});

  factory EspaceProprietaireModel.fromJson(Map<String, dynamic> json) =>
      EspaceProprietaireModel(
        id: '${json['id']}',
        nomAffiche: json['display_name'] as String? ?? '',
        societe: json['company_name'] as String?,
        ville: json['city'] as String?,
        statut: json['status'] as String?,
      );
}

class DroitsAbonnementModel extends DroitsAbonnement {
  const DroitsAbonnementModel(
      {required super.actif, super.statut, super.plan, super.finPeriode});

  factory DroitsAbonnementModel.fromJson(Map<String, dynamic> json) {
    final abonnement = json['abonnement'] as Map?;
    final plan = json['plan'] as Map?;
    return DroitsAbonnementModel(
      actif: json['actif'] == true,
      statut: abonnement?['status'] as String?,
      plan: plan?['name'] as String?,
      finPeriode: abonnement?['current_period_end'] as String?,
    );
  }
}

class CompteModel extends Compte {
  const CompteModel(
      {required super.utilisateur, super.espace, super.abonnement});

  factory CompteModel.fromJson(Map<String, dynamic> json) => CompteModel(
        utilisateur: UtilisateurModel.fromJson(
            Map<String, dynamic>.from(json['user'] as Map)),
        espace: json['owner'] == null
            ? null
            : EspaceProprietaireModel.fromJson(
                Map<String, dynamic>.from(json['owner'] as Map)),
        abonnement: json['abonnement'] == null
            ? null
            : DroitsAbonnementModel.fromJson(
                Map<String, dynamic>.from(json['abonnement'] as Map)),
      );
}
