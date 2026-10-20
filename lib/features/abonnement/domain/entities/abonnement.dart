import 'package:equatable/equatable.dart';

/// Consommation d'une limite du plan (`max` absent : illimité).
class Quota extends Equatable {
  final int utilise;
  final int? max;
  const Quota({this.utilise = 0, this.max});

  @override
  List<Object?> get props => [utilise, max];
}

/// Abonnement en cours (§ 31) : plan, période, consommation.
class EtatAbonnement extends Equatable {
  final bool actif;
  final String? statut;
  final String? planCode;
  final String? planNom;
  final String? finPeriode;
  final Quota? immeubles;
  final Quota? appartements;
  final Quota? whatsappCeMois;

  const EtatAbonnement({
    this.actif = false,
    this.statut,
    this.planCode,
    this.planNom,
    this.finPeriode,
    this.immeubles,
    this.appartements,
    this.whatsappCeMois,
  });

  @override
  List<Object?> get props => [
        actif,
        statut,
        planCode,
        planNom,
        finPeriode,
        immeubles,
        appartements,
        whatsappCeMois
      ];
}

class PlanAbonnement extends Equatable {
  final String code;
  final String nom;
  final int prix;
  final String? periodeFacturation;
  final int? maxImmeubles;
  final int? maxAppartements;
  final List<String> fonctionnalites;

  const PlanAbonnement({
    required this.code,
    required this.nom,
    this.prix = 0,
    this.periodeFacturation,
    this.maxImmeubles,
    this.maxAppartements,
    this.fonctionnalites = const [],
  });

  @override
  List<Object?> get props => [
        code,
        nom,
        prix,
        periodeFacturation,
        maxImmeubles,
        maxAppartements,
        fonctionnalites
      ];
}

class PaiementAbonnement extends Equatable {
  final String? reference;
  final String? planNom;
  final int mois;
  final num? montant;
  final String? statut;
  final String? date;

  /// Paiement initié non terminé : lien pour le reprendre.
  final String? checkoutUrl;

  const PaiementAbonnement(
      {this.reference,
      this.planNom,
      this.mois = 0,
      this.montant,
      this.statut,
      this.date,
      this.checkoutUrl});

  @override
  List<Object?> get props =>
      [reference, planNom, mois, montant, statut, date, checkoutUrl];
}

/// Écran abonnement : état, plans proposés, derniers paiements.
class FicheAbonnement extends Equatable {
  final EtatAbonnement etat;
  final List<PlanAbonnement> plans;
  final List<PaiementAbonnement> paiements;
  const FicheAbonnement(
      {required this.etat, required this.plans, required this.paiements});

  @override
  List<Object?> get props => [etat, plans, paiements];
}
