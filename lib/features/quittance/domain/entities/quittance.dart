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
  final String? periodeDebut;
  final String? periodeFin;
  final String? logementNumero;
  final String? immeuble;

  /// Références des paiements qui ont soldé l'échéance.
  final List<String> referencesPaiement;

  const Quittance({
    required this.id,
    this.numero,
    this.libelleEcheance,
    this.locataire,
    this.emiseLe,
    this.montant,
    this.annulee = false,
    this.periodeDebut,
    this.periodeFin,
    this.logementNumero,
    this.immeuble,
    this.referencesPaiement = const [],
  });

  @override
  List<Object?> get props => [
    id,
    numero,
    libelleEcheance,
    locataire,
    emiseLe,
    montant,
    annulee,
    periodeDebut,
    periodeFin,
    logementNumero,
    immeuble,
    referencesPaiement,
  ];
}
