import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Locataire en impayé (§ 48 « Qui n'a pas payé ? »).
class Debiteur extends Equatable {
  final PersonneResume locataire;
  final String? immeuble;
  final String? appartement;
  final String? depuis;
  final num? montant;

  /// Nombre d'échéances impayées.
  final int echeances;

  const Debiteur({
    required this.locataire,
    this.immeuble,
    this.appartement,
    this.depuis,
    this.montant,
    this.echeances = 0,
  });

  @override
  List<Object?> get props => [
    locataire,
    immeuble,
    appartement,
    depuis,
    montant,
    echeances,
  ];
}

/// Revenus et dépenses mois par mois sur une fenêtre glissante (`GET /dashboard/graphiques`).
class SerieFinanciere extends Equatable {
  final List<MontantMensuel> revenus;
  final Map<String, int> depenses;
  const SerieFinanciere({required this.revenus, required this.depenses});

  int get totalRevenus => revenus.fold(0, (s, r) => s + r.total);
  int get totalDepenses => depenses.values.fold(0, (s, d) => s + d);

  @override
  List<Object?> get props => [revenus, depenses];
}

class MontantMensuel extends Equatable {
  final String mois;
  final int total;
  const MontantMensuel(this.mois, this.total);

  @override
  List<Object?> get props => [mois, total];
}

class DepenseCategorie extends Equatable {
  final String nom;
  final num? total;
  const DepenseCategorie(this.nom, this.total);

  @override
  List<Object?> get props => [nom, total];
}

/// Tableau de bord « immédiatement compréhensible » (§ 6, § 48).
class TableauDeBord extends Equatable {
  final String mois;
  final int immeubles;
  final int appartements;
  final int occupes;
  final int disponibles;
  final num? tauxOccupation;
  final num? aRecevoir;
  final num? encaisses;

  /// Tout l'argent reçu dans le mois, avances sur les mois suivants comprises.
  final num? revenus;
  final num? impayes;
  final num? depenses;
  final num? resultat;
  final int preuvesAValider;

  /// Ce qu'il reste à percevoir sur les loyers attendus ce mois-ci.
  num get resteARecevoir {
    final reste = (aRecevoir ?? 0) - (encaisses ?? 0);
    return reste > 0 ? reste : 0;
  }

  final int aRapprocher;
  final int facturesARepartir;
  final int incidentsOuverts;
  final int travauxEnCours;
  final int totalDebiteurs;
  final List<Debiteur> debiteurs;

  /// Graphiques des 6 derniers mois.
  final List<MontantMensuel> revenusMensuels;
  final Map<String, int> depensesMensuelles;
  final List<DepenseCategorie> depensesParCategorie;

  const TableauDeBord({
    required this.mois,
    this.immeubles = 0,
    this.appartements = 0,
    this.occupes = 0,
    this.disponibles = 0,
    this.tauxOccupation,
    this.aRecevoir,
    this.encaisses,
    this.revenus,
    this.impayes,
    this.depenses,
    this.resultat,
    this.preuvesAValider = 0,
    this.aRapprocher = 0,
    this.facturesARepartir = 0,
    this.incidentsOuverts = 0,
    this.travauxEnCours = 0,
    this.totalDebiteurs = 0,
    this.debiteurs = const [],
    this.revenusMensuels = const [],
    this.depensesMensuelles = const {},
    this.depensesParCategorie = const [],
  });

  @override
  List<Object?> get props => [
    mois,
    immeubles,
    appartements,
    occupes,
    disponibles,
    tauxOccupation,
    aRecevoir,
    encaisses,
    revenus,
    impayes,
    depenses,
    resultat,
    preuvesAValider,
    aRapprocher,
    facturesARepartir,
    incidentsOuverts,
    travauxEnCours,
    totalDebiteurs,
    debiteurs,
    revenusMensuels,
    depensesMensuelles,
    depensesParCategorie,
  ];
}
