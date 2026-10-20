import 'package:equatable/equatable.dart';

/// Espace du bailleur (`GET /compte` → `owner`).
class EspaceProprietaire extends Equatable {
  final String id;
  final String nomAffiche;
  final String? societe;
  final String? ville;
  final String? statut;

  const EspaceProprietaire(
      {required this.id,
      required this.nomAffiche,
      this.societe,
      this.ville,
      this.statut});

  @override
  List<Object?> get props => [id, nomAffiche, societe, ville, statut];
}
