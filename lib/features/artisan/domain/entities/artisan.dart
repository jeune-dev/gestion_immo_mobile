import 'package:equatable/equatable.dart';

/// Artisan (§ 24).
class Artisan extends Equatable {
  final String id;
  final String nom;
  final String? metier;
  final String? telephone;
  final String? email;
  final String? notes;
  final bool actif;
  final int interventions;
  final num? totalPaye;

  const Artisan({
    required this.id,
    required this.nom,
    this.metier,
    this.telephone,
    this.email,
    this.notes,
    this.actif = true,
    this.interventions = 0,
    this.totalPaye,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        metier,
        telephone,
        email,
        notes,
        actif,
        interventions,
        totalPaye
      ];
}
