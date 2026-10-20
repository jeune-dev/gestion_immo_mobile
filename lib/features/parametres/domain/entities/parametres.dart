import 'package:equatable/equatable.dart';

/// Coordonnées du bailleur, reprises sur les quittances.
class EspaceBailleur extends Equatable {
  final String? nomAffiche;
  final String? societe;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? ville;

  const EspaceBailleur(
      {this.nomAffiche,
      this.societe,
      this.telephone,
      this.email,
      this.adresse,
      this.ville});

  @override
  List<Object?> get props =>
      [nomAffiche, societe, telephone, email, adresse, ville];
}

/// Règles de gestion : relances (§ 14), état des lieux (§ 52.4), caution (§ 55), canaux (§ 54.3).
class ReglagesGestion extends Equatable {
  /// Jours de relance par rapport à l'échéance (négatifs : avant).
  final List<int> relances;
  final int? preavisEcheance;
  final int? delaiGrace;
  final int? delaiReponseEdl;
  final int? delaiRestitutionCaution;
  final String? politiqueEdlEntree;
  final List<String> ordreCanaux;
  final String? strategieNotification;

  const ReglagesGestion({
    this.relances = const [],
    this.preavisEcheance,
    this.delaiGrace,
    this.delaiReponseEdl,
    this.delaiRestitutionCaution,
    this.politiqueEdlEntree,
    this.ordreCanaux = const [],
    this.strategieNotification,
  });

  @override
  List<Object?> get props => [
        relances,
        preavisEcheance,
        delaiGrace,
        delaiReponseEdl,
        delaiRestitutionCaution,
        politiqueEdlEntree,
        ordreCanaux,
        strategieNotification,
      ];
}

class ParametresProprietaire extends Equatable {
  final EspaceBailleur espace;
  final ReglagesGestion reglages;
  const ParametresProprietaire({required this.espace, required this.reglages});

  @override
  List<Object?> get props => [espace, reglages];
}
