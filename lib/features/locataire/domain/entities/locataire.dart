import 'package:equatable/equatable.dart';
import 'package:gestion_immo_mobile/core/models/logement_resume.dart';

/// Code d'invitation à transmettre au locataire (§ 5 option A).
class Invitation extends Equatable {
  final String code;
  final String? expireLe;

  const Invitation({required this.code, this.expireLe});

  @override
  List<Object?> get props => [code, expireLe];
}

/// Bail du locataire, vu depuis sa fiche.
class BailDuLocataire extends Equatable {
  final String id;
  final String? reference;
  final String? statut;
  final num? loyer;
  final LogementResume? logement;

  const BailDuLocataire({
    required this.id,
    this.reference,
    this.statut,
    this.loyer,
    this.logement,
  });

  @override
  List<Object?> get props => [id, reference, statut, loyer, logement];
}

class PaiementRecent extends Equatable {
  final String? reference;
  final String? date;
  final String? moyen;
  final num? montant;

  const PaiementRecent({this.reference, this.date, this.moyen, this.montant});

  @override
  List<Object?> get props => [reference, date, moyen, montant];
}

class SoldeLocataire extends Equatable {
  final num? resteDu;
  final num? impayes;
  final int echeancesEnRetard;

  const SoldeLocataire({
    this.resteDu,
    this.impayes,
    this.echeancesEnRetard = 0,
  });

  @override
  List<Object?> get props => [resteDu, impayes, echeancesEnRetard];
}

class Locataire extends Equatable {
  final String id;
  final String prenom;
  final String nom;
  final String? telephone;
  final String? email;
  final String? typePiece;
  final String? numeroPiece;
  final String? notes;

  /// Le locataire a activé son compte dans l'application.
  final bool compteActif;
  final bool consentementWhatsapp;

  /// Appartement du bail actif (liste des locataires).
  final LogementResume? logementCourant;

  /// Un code d'invitation non encore utilisé existe.
  final bool invitationEnvoyee;
  final List<BailDuLocataire> baux;
  final SoldeLocataire solde;
  final List<PaiementRecent> paiementsRecents;

  const Locataire({
    required this.id,
    required this.prenom,
    required this.nom,
    this.telephone,
    this.email,
    this.typePiece,
    this.numeroPiece,
    this.notes,
    this.compteActif = false,
    this.consentementWhatsapp = false,
    this.logementCourant,
    this.invitationEnvoyee = false,
    this.baux = const [],
    this.solde = const SoldeLocataire(),
    this.paiementsRecents = const [],
  });

  String get nomComplet => '$prenom $nom'.trim();

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        prenom,
        nom,
        telephone,
        email,
        typePiece,
        numeroPiece,
        notes,
        compteActif,
        consentementWhatsapp,
        logementCourant,
        invitationEnvoyee,
        baux,
        solde,
        paiementsRecents,
      ];
}

/// Locataire créé, avec son code d'invitation s'il a été demandé.
class LocataireCree extends Equatable {
  final Locataire locataire;
  final Invitation? invitation;

  const LocataireCree({required this.locataire, this.invitation});

  @override
  List<Object?> get props => [locataire, invitation];
}
