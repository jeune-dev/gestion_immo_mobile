import 'package:equatable/equatable.dart';

import 'echeance.dart';

/// Paiement imputé sur une échéance (une échéance peut être soldée en
/// plusieurs fois).
class ImputationPaiement extends Equatable {
  final int montant;
  final String? imputeLe;
  final String? payeLe;
  final String? reference;
  final String? moyen;

  const ImputationPaiement({
    this.montant = 0,
    this.imputeLe,
    this.payeLe,
    this.reference,
    this.moyen,
  });

  @override
  List<Object?> get props => [montant, imputeLe, payeLe, reference, moyen];
}

/// Quittance émise pour une échéance soldée.
class QuittanceEmise extends Equatable {
  final String id;
  final String? numero;
  final String? emiseLe;

  const QuittanceEmise({required this.id, this.numero, this.emiseLe});

  @override
  List<Object?> get props => [id, numero, emiseLe];
}

/// Fiche d'une échéance (§ 11) : période, décomposition loyer / charges,
/// paiements imputés et quittance.
class EcheanceDetail extends Equatable {
  final Echeance echeance;
  final String? periodeDebut;
  final String? periodeFin;
  final int? loyer;
  final int? charges;
  final String? immeuble;
  final String? payeeLe;
  final List<ImputationPaiement> imputations;
  final QuittanceEmise? quittance;

  const EcheanceDetail({
    required this.echeance,
    this.periodeDebut,
    this.periodeFin,
    this.loyer,
    this.charges,
    this.immeuble,
    this.payeeLe,
    this.imputations = const [],
    this.quittance,
  });

  @override
  List<Object?> get props => [
    echeance,
    periodeDebut,
    periodeFin,
    loyer,
    charges,
    immeuble,
    payeeLe,
    imputations,
    quittance,
  ];
}
