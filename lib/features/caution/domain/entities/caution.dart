import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';

/// Mouvement de caution : versement, retenue (justifiée), restitution (§ 55).
class MouvementCaution extends Equatable {
  final String id;
  final String? type;
  final String? motif;
  final String? date;
  final String? description;
  final num? montant;
  final String? statutContestation;
  final String? messageContestation;
  final String? reponseProprietaire;

  bool get contestee => statutContestation == 'conteste';

  const MouvementCaution({
    required this.id,
    this.type,
    this.motif,
    this.date,
    this.description,
    this.montant,
    this.statutContestation,
    this.messageContestation,
    this.reponseProprietaire,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        motif,
        date,
        description,
        montant,
        statutContestation,
        messageContestation,
        reponseProprietaire
      ];
}

/// Caution d'un bail (§ 55) : versée, détenue, retenue, restituée ou en litige.
class Caution extends Equatable {
  final String id;
  final String? statut;
  final int attendue;
  final int recue;
  final int retenue;
  final int restituee;

  /// Montant détenu par le propriétaire.
  final int solde;
  final String? restituerAvant;
  final String? bailReference;
  final String? bailStatut;
  final PersonneResume? locataire;
  final List<MouvementCaution> mouvements;

  int get resteAVerser => attendue - recue;

  /// Retenue et restitution ne sont possibles qu'une fois le bail terminé.
  bool get bailTermine => ['termine', 'clos'].contains(bailStatut);

  const Caution({
    required this.id,
    this.statut,
    this.attendue = 0,
    this.recue = 0,
    this.retenue = 0,
    this.restituee = 0,
    this.solde = 0,
    this.restituerAvant,
    this.bailReference,
    this.bailStatut,
    this.locataire,
    this.mouvements = const [],
  });

  @override
  List<Object?> get props => [
        id,
        statut,
        attendue,
        recue,
        retenue,
        restituee,
        solde,
        restituerAvant,
        bailReference,
        bailStatut,
        locataire,
        mouvements,
      ];
}
