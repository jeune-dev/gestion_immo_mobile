import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Quittance de loyer (§ 13).
class Quittance extends Equatable {
  final String id;
  final String? numero;
  final String? libelleEcheance;
  final PersonneResume? locataire;
  final String? emiseLe;
  final num? montant;
  final bool annulee;

  const Quittance(
      {required this.id,
      this.numero,
      this.libelleEcheance,
      this.locataire,
      this.emiseLe,
      this.montant,
      this.annulee = false});

  @override
  List<Object?> get props =>
      [id, numero, libelleEcheance, locataire, emiseLe, montant, annulee];
}
