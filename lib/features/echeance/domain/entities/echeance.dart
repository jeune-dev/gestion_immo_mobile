import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Échéance de loyer (§ 11).
class Echeance extends Equatable {
  final String id;
  final String? bailId;
  final String? libelle;
  final int montantDu;
  final int montantPaye;
  final String? dateEcheance;
  final String? statut;
  final PersonneResume? locataire;
  final String? logementNumero;

  int get reste => montantDu - montantPaye;

  /// Peut encore recevoir un paiement.
  bool get payable =>
      ['a_payer', 'partiellement_paye', 'en_retard'].contains(statut);

  const Echeance({
    required this.id,
    this.bailId,
    this.libelle,
    this.montantDu = 0,
    this.montantPaye = 0,
    this.dateEcheance,
    this.statut,
    this.locataire,
    this.logementNumero,
  });

  @override
  List<Object?> get props => [
        id,
        bailId,
        libelle,
        montantDu,
        montantPaye,
        dateEcheance,
        statut,
        locataire,
        logementNumero
      ];
}
