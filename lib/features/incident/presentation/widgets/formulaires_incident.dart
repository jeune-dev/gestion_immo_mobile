import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/sources_appartement.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/widgets/sources_artisan.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/sources_immeuble.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/incident/domain/usecases/creer_incident.dart';
import 'package:gestion_immo_mobile/features/incident/domain/usecases/planifier_travaux.dart';

/// Incident constaté par le propriétaire lui-même.
Future<Incident?> nouvelIncident(BuildContext context) {
  final cle = nouvelleCle();
  return EcranFormulaire.ouvrir<Incident>(
    context,
    EcranFormulaire(
      titre: 'Nouvel incident',
      champs: [
        Champ('building_id', 'Immeuble',
            type: TypeChamp.entite,
            obligatoire: true,
            entite: sourceImmeubles()),
        Champ('apartment_id', 'Appartement (facultatif)',
            type: TypeChamp.entite, entite: sourceAppartements()),
        const Champ('category', 'Catégorie',
            type: TypeChamp.selection,
            referentiel: 'categorie_incident',
            obligatoire: true),
        const Champ('title', 'Titre',
            obligatoire: true, minLongueur: 2, maxLongueur: 150),
        const Champ('description', 'Description',
            type: TypeChamp.multiligne,
            obligatoire: true,
            minLongueur: 2,
            maxLongueur: 5000),
      ],
      messageSucces: 'Incident enregistré',
      envoyer: (c) async => (await sl<CreerIncident>()(c, cle: cle)).ouLeve(),
    ),
  );
}

/// Travaux planifiés depuis l'incident (§ 23) : le locataire est prévenu.
Future<bool> planifierTravaux(BuildContext context, Incident i) async {
  final cle = nouvelleCle();
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Planifier des travaux',
      initial: {'title': i.titre, 'priority': 'normale', 'status': 'valide'},
      champs: [
        const Champ('title', 'Intitulé', maxLongueur: 150),
        const Champ('category', 'Catégorie',
            type: TypeChamp.selection,
            referentiel: 'categorie_travaux',
            obligatoire: true),
        const Champ('priority', 'Priorité',
            type: TypeChamp.selection, referentiel: 'priorite'),
        Champ('contractor_id', 'Artisan',
            type: TypeChamp.entite, entite: sourceArtisans()),
        const Champ('estimated_amount', 'Coût estimé', type: TypeChamp.montant),
        const Champ('scheduled_for', 'Date prévue', type: TypeChamp.date),
        const Champ('note', 'Note pour le locataire',
            type: TypeChamp.multiligne, maxLongueur: 2000),
      ],
      libelleEnvoi: 'Planifier',
      messageSucces: 'Travaux planifiés',
      envoyer: (c) async {
        (await sl<PlanifierTravaux>()(i.id, c, cle: cle)).ouLeve();
        return true;
      },
    ),
  );
  return r != null;
}
