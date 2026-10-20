import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/entities/immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/sources_immeuble.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/usecases/creer_appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/usecases/modifier_appartement.dart';

/// Création ou modification d'un appartement (§ 8). Renvoie l'appartement enregistré.
Future<Appartement?> formulaireAppartement(BuildContext context,
    {Appartement? existant, Immeuble? immeuble}) {
  return EcranFormulaire.ouvrir<Appartement>(
    context,
    EcranFormulaire(
      titre: existant == null ? 'Nouvel appartement' : 'Modifier l’appartement',
      initial: existant != null
          ? {
              'number': existant.numero,
              'type': existant.type,
              'floor': existant.etage,
              'rent_amount': existant.loyer,
              'charges_amount': existant.charges,
              'surface': existant.surface,
              'rooms_count': existant.nbPieces,
              'charge_coefficient': existant.coefficientCharges,
              'is_furnished': existant.meuble,
              'description': existant.description,
            }
          : {
              if (immeuble != null) 'building_id': immeuble.id,
              if (immeuble != null) 'building_id__libelle': immeuble.nom,
              'charges_amount': 0
            },
      messageSucces:
          existant == null ? 'Appartement créé' : 'Appartement modifié',
      champs: [
        if (existant == null)
          Champ('building_id', 'Immeuble',
              type: TypeChamp.entite,
              obligatoire: true,
              entite: sourceImmeubles()),
        const Champ('number', 'Numéro',
            obligatoire: true, maxLongueur: 30, indice: 'Ex. A12'),
        const Champ('type', 'Type',
            type: TypeChamp.selection,
            referentiel: 'type_appartement',
            obligatoire: true),
        const Champ('floor', 'Étage',
            type: TypeChamp.entier, min: -5, max: 300),
        const Champ('rent_amount', 'Loyer mensuel',
            type: TypeChamp.montant, obligatoire: true),
        const Champ('charges_amount', 'Charges mensuelles',
            type: TypeChamp.montant),
        const Champ('surface', 'Surface (m²)',
            type: TypeChamp.decimal, max: 100000),
        const Champ('rooms_count', 'Nombre de pièces',
            type: TypeChamp.entier, min: 0, max: 100),
        const Champ(
          'charge_coefficient',
          'Coefficient de charges',
          type: TypeChamp.decimal,
          indice:
              'Utilisé pour répartir les factures communes « selon coefficient » (1 par défaut).',
        ),
        const Champ('is_furnished', 'Meublé', type: TypeChamp.interrupteur),
        const Champ('description', 'Description',
            type: TypeChamp.multiligne, maxLongueur: 5000),
      ],
      envoyer: (corps) async => (existant == null
              ? await sl<CreerAppartement>()(corps)
              : await sl<ModifierAppartement>()(existant.id, corps))
          .ouLeve(),
    ),
  );
}
