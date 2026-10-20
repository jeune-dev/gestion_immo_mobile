import 'package:equatable/equatable.dart';

/// Montant libellé (dépenses par catégorie…).
class LigneMontant extends Equatable {
  final String libelle;
  final num? montant;
  const LigneMontant(this.libelle, this.montant);

  @override
  List<Object?> get props => [libelle, montant];
}

/// Résultat d'un immeuble dans le rapport financier.
class FinancierImmeuble extends Equatable {
  final String nom;
  final num? revenus;
  final num? depenses;
  final num? impayes;
  final num? beneficeNet;

  const FinancierImmeuble(
      {required this.nom,
      this.revenus,
      this.depenses,
      this.impayes,
      this.beneficeNet});

  @override
  List<Object?> get props => [nom, revenus, depenses, impayes, beneficeNet];
}

/// Rapport financier (§ 26).
class RapportFinancier extends Equatable {
  final num? loyers;
  final num? chargesRecuperees;
  final num? autresRevenus;
  final num? totalRevenus;
  final num? totalDepenses;
  final num? beneficeNet;
  final String? impayesDate;
  final num? impayesMontant;
  final int impayesEcheances;
  final int impayesLocataires;
  final List<LigneMontant> depensesParCategorie;
  final int nombreFactures;
  final num? facturesTotal;
  final num? chargesRefacturees;
  final num? chargesRecupereesLocataires;
  final num? resteARecouvrer;
  final num? aChargeProprietaire;
  final List<FinancierImmeuble> parImmeuble;

  const RapportFinancier({
    this.loyers,
    this.chargesRecuperees,
    this.autresRevenus,
    this.totalRevenus,
    this.totalDepenses,
    this.beneficeNet,
    this.impayesDate,
    this.impayesMontant,
    this.impayesEcheances = 0,
    this.impayesLocataires = 0,
    this.depensesParCategorie = const [],
    this.nombreFactures = 0,
    this.facturesTotal,
    this.chargesRefacturees,
    this.chargesRecupereesLocataires,
    this.resteARecouvrer,
    this.aChargeProprietaire,
    this.parImmeuble = const [],
  });

  @override
  List<Object?> get props => [
        loyers,
        chargesRecuperees,
        autresRevenus,
        totalRevenus,
        totalDepenses,
        beneficeNet,
        impayesDate,
        impayesMontant,
        impayesEcheances,
        impayesLocataires,
        depensesParCategorie,
        nombreFactures,
        facturesTotal,
        chargesRefacturees,
        chargesRecupereesLocataires,
        resteARecouvrer,
        aChargeProprietaire,
        parImmeuble,
      ];
}

class OccupationImmeuble extends Equatable {
  final String nom;
  final String? ville;
  final int appartements;
  final int occupes;
  final num? tauxOccupation;

  const OccupationImmeuble(
      {required this.nom,
      this.ville,
      this.appartements = 0,
      this.occupes = 0,
      this.tauxOccupation});

  @override
  List<Object?> get props =>
      [nom, ville, appartements, occupes, tauxOccupation];
}

/// Rapport d'occupation (§ 26).
class RapportImmobilier extends Equatable {
  final int immeubles;
  final int appartements;
  final int occupes;
  final int disponibles;
  final int enTravaux;
  final num? tauxOccupation;
  final num? tauxOccupationPeriode;
  final num? loyerMensuelOccupes;
  final num? loyerMoyen;
  final num? loyerPotentiel;
  final num? manqueAGagner;
  final List<OccupationImmeuble> parImmeuble;

  const RapportImmobilier({
    this.immeubles = 0,
    this.appartements = 0,
    this.occupes = 0,
    this.disponibles = 0,
    this.enTravaux = 0,
    this.tauxOccupation,
    this.tauxOccupationPeriode,
    this.loyerMensuelOccupes,
    this.loyerMoyen,
    this.loyerPotentiel,
    this.manqueAGagner,
    this.parImmeuble = const [],
  });

  @override
  List<Object?> get props => [
        immeubles,
        appartements,
        occupes,
        disponibles,
        enTravaux,
        tauxOccupation,
        tauxOccupationPeriode,
        loyerMensuelOccupes,
        loyerMoyen,
        loyerPotentiel,
        manqueAGagner,
        parImmeuble,
      ];
}

class LocataireEnImpaye extends Equatable {
  final String nom;
  final int echeances;
  final String? depuis;
  final num? montant;

  const LocataireEnImpaye(
      {required this.nom, this.echeances = 0, this.depuis, this.montant});

  @override
  List<Object?> get props => [nom, echeances, depuis, montant];
}

/// Arrivée ou départ d'un locataire sur la période.
class MouvementLocataire extends Equatable {
  final String nom;
  final String? immeuble;
  final String? appartement;
  final String? date;

  const MouvementLocataire(
      {required this.nom, this.immeuble, this.appartement, this.date});

  @override
  List<Object?> get props => [nom, immeuble, appartement, date];
}

/// Rapport locataires (§ 26).
class RapportLocataires extends Equatable {
  final int actifs;
  final int nombreArrivees;
  final int nombreDeparts;
  final num? impayesTotal;
  final List<LocataireEnImpaye> enImpaye;
  final List<MouvementLocataire> arrivees;
  final List<MouvementLocataire> departs;

  const RapportLocataires({
    this.actifs = 0,
    this.nombreArrivees = 0,
    this.nombreDeparts = 0,
    this.impayesTotal,
    this.enImpaye = const [],
    this.arrivees = const [],
    this.departs = const [],
  });

  @override
  List<Object?> get props => [
        actifs,
        nombreArrivees,
        nombreDeparts,
        impayesTotal,
        enImpaye,
        arrivees,
        departs
      ];
}

class TravauxParCategorie extends Equatable {
  final String? categorie;
  final int nombre;
  final int termines;
  final num? coutReel;

  const TravauxParCategorie(
      {this.categorie, this.nombre = 0, this.termines = 0, this.coutReel});

  @override
  List<Object?> get props => [categorie, nombre, termines, coutReel];
}

/// Rapport travaux (§ 26).
class RapportTravaux extends Equatable {
  final int crees;
  final int termines;
  final int enCours;
  final int enAttente;
  final int annules;
  final num? coutEstime;
  final num? coutReel;
  final num? depensesLiees;
  final List<TravauxParCategorie> parCategorie;

  const RapportTravaux({
    this.crees = 0,
    this.termines = 0,
    this.enCours = 0,
    this.enAttente = 0,
    this.annules = 0,
    this.coutEstime,
    this.coutReel,
    this.depensesLiees,
    this.parCategorie = const [],
  });

  @override
  List<Object?> get props => [
        crees,
        termines,
        enCours,
        enAttente,
        annules,
        coutEstime,
        coutReel,
        depensesLiees,
        parCategorie
      ];
}

/// Rentabilité d'un appartement, classée par résultat net (§ 48).
class LigneRentabilite extends Equatable {
  final int? rang;
  final String? immeuble;
  final String? appartement;
  final num? revenus;
  final num? depenses;
  final num? tauxOccupation;
  final num? resultatNet;

  const LigneRentabilite(
      {this.rang,
      this.immeuble,
      this.appartement,
      this.revenus,
      this.depenses,
      this.tauxOccupation,
      this.resultatNet});

  @override
  List<Object?> get props => [
        rang,
        immeuble,
        appartement,
        revenus,
        depenses,
        tauxOccupation,
        resultatNet
      ];
}
