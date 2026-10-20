import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';

/// Logement loué (« Mon logement », § 28).
class LogementLocataire extends Equatable {
  final String bailId;
  final String? statutBail;
  final String? appartementNumero;
  final String? appartementType;
  final String? immeubleNom;
  final String? immeubleAdresse;
  final String? ville;
  final int loyer;
  final int charges;
  final String? periodicite;
  final String? proprietaireNom;
  final String? proprietaireTelephone;

  /// Accueil uniquement : prochaine échéance à payer et sommes dues.
  final Echeance? prochaineEcheance;
  final int montantEnRetard;
  final int montantDu;

  bool get actif => statutBail == 'actif';

  const LogementLocataire({
    required this.bailId,
    this.statutBail,
    this.appartementNumero,
    this.appartementType,
    this.immeubleNom,
    this.immeubleAdresse,
    this.ville,
    this.loyer = 0,
    this.charges = 0,
    this.periodicite,
    this.proprietaireNom,
    this.proprietaireTelephone,
    this.prochaineEcheance,
    this.montantEnRetard = 0,
    this.montantDu = 0,
  });

  @override
  List<Object?> get props => [
        bailId,
        statutBail,
        appartementNumero,
        appartementType,
        immeubleNom,
        immeubleAdresse,
        ville,
        loyer,
        charges,
        periodicite,
        proprietaireNom,
        proprietaireTelephone,
        prochaineEcheance,
        montantEnRetard,
        montantDu,
      ];
}

/// Numéro Wave / Orange Money du bailleur pour un paiement direct avec preuve.
class MoyenPreuve extends Equatable {
  final String portefeuille;
  final String? libelle;
  final String? numero;
  const MoyenPreuve({required this.portefeuille, this.libelle, this.numero});

  @override
  List<Object?> get props => [portefeuille, libelle, numero];
}

/// Moyens de paiement ouverts au locataire pour un bail (§ 51).
class MoyensPaiementLocataire extends Equatable {
  /// Portefeuilles payables en ligne (PayDunya).
  final List<String> integres;
  final List<MoyenPreuve> preuves;
  final String? beneficiaire;
  final bool especes;

  const MoyensPaiementLocataire(
      {this.integres = const [],
      this.preuves = const [],
      this.beneficiaire,
      this.especes = false});

  @override
  List<Object?> get props => [integres, preuves, beneficiaire, especes];
}

/// Paiement en ligne initié : transaction à suivre et page de paiement à ouvrir.
class DemandePaiement extends Equatable {
  final String transactionId;
  final String? checkoutUrl;
  const DemandePaiement({required this.transactionId, this.checkoutUrl});

  @override
  List<Object?> get props => [transactionId, checkoutUrl];
}
