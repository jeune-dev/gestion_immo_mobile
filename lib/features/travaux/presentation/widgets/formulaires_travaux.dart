import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/sources_appartement.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/widgets/sources_artisan.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/sources_immeuble.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/entities/travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/usecases/changer_statut_travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/usecases/creer_travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/usecases/modifier_travaux.dart';

/// Transitions de statut autorisées par l'API (`config/transitions.js`, TRAVAUX).
const transitionsTravaux = {
  'signale': ['a_valider', 'valide', 'annule'],
  'a_valider': ['valide', 'annule'],
  'valide': ['artisan_assigne', 'en_cours', 'annule'],
  'artisan_assigne': ['en_cours', 'valide', 'annule'],
  'en_cours': ['termine', 'annule'],
};

/// Création ou modification d'un chantier (§ 18).
Future<Travaux?> formulaireTravaux(BuildContext context, {Travaux? existant}) {
  final cle = nouvelleCle();
  return EcranFormulaire.ouvrir<Travaux>(
    context,
    EcranFormulaire(
      titre: existant == null ? 'Nouveaux travaux' : 'Modifier les travaux',
      initial: existant == null
          ? const {'priority': 'normale', 'status': 'signale'}
          : {
              'title': existant.titre,
              'category': existant.categorie,
              'priority': existant.priorite,
              'apartment_id': existant.appartementId,
              if (existant.appartementNumero != null)
                'apartment_id__libelle':
                    'Appartement ${existant.appartementNumero}',
              'description': existant.description,
              'estimated_amount': existant.coutEstime?.round(),
              'contractor_id': existant.artisanId,
              if (existant.artisanNom != null)
                'contractor_id__libelle': existant.artisanNom,
              'scheduled_for': existant.prevuLe,
            },
      champs: [
        if (existant == null)
          Champ('building_id', 'Immeuble',
              type: TypeChamp.entite,
              obligatoire: true,
              entite: sourceImmeubles()),
        const Champ('title', 'Intitulé',
            obligatoire: true,
            maxLongueur: 150,
            indice: 'Ex. Fuite salle de bain'),
        const Champ('category', 'Catégorie',
            type: TypeChamp.selection,
            referentiel: 'categorie_travaux',
            obligatoire: true),
        const Champ('priority', 'Priorité',
            type: TypeChamp.selection,
            referentiel: 'priorite',
            obligatoire: true),
        Champ('apartment_id', 'Appartement (facultatif)',
            type: TypeChamp.entite, entite: sourceAppartements()),
        const Champ('description', 'Description',
            type: TypeChamp.multiligne, maxLongueur: 5000),
        const Champ('estimated_amount', 'Coût estimé',
            type: TypeChamp.montant, nullable: true),
        Champ('contractor_id', 'Artisan',
            type: TypeChamp.entite, entite: sourceArtisans()),
        const Champ('scheduled_for', 'Date prévue', type: TypeChamp.date),
      ],
      messageSucces: existant == null ? 'Travaux créés' : 'Travaux modifiés',
      envoyer: (c) async => (existant == null
              ? await sl<CreerTravaux>()(c, cle: cle)
              : await sl<ModifierTravaux>()(existant.id, c))
          .ouLeve(),
    ),
  );
}

/// Passage au statut [statut] (artisan exigé à l'assignation, coût réel à la fin, motif à l'annulation).
Future<bool> changerStatutTravaux(
    BuildContext context, Travaux t, String statut) async {
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: refs.libelle('statut_travaux', statut),
      initial: {
        if (t.artisanId != null) 'contractor_id': t.artisanId,
        if (t.artisanNom != null) 'contractor_id__libelle': t.artisanNom,
        'actual_amount': (t.coutReel ?? t.coutEstime)?.round(),
      },
      intro: statut == 'termine'
          ? const Text(
              'Un chantier terminé est figé : son historique et ses photos ne pourront plus être modifiés.')
          : null,
      champs: [
        if (statut == 'artisan_assigne')
          Champ('contractor_id', 'Artisan',
              type: TypeChamp.entite,
              obligatoire: true,
              entite: sourceArtisans()),
        if (statut == 'termine')
          const Champ('actual_amount', 'Coût réel', type: TypeChamp.montant),
        Champ(
          'comment',
          statut == 'annule' ? 'Motif' : 'Commentaire',
          type: TypeChamp.multiligne,
          obligatoire: statut == 'annule',
          maxLongueur: 2000,
        ),
      ],
      libelleEnvoi: 'Confirmer',
      messageSucces: 'Statut mis à jour',
      envoyer: (c) async {
        (await sl<ChangerStatutTravaux>()(t.id, {...c, 'status': statut}))
            .ouLeve();
        return true;
      },
    ),
  );
  return r != null;
}
