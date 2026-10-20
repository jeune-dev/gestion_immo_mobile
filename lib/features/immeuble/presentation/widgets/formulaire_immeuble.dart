import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/entities/immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/usecases/creer_immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/usecases/modifier_immeuble.dart';

/// Création ou modification d'un immeuble (§ 7). Renvoie l'immeuble enregistré.
Future<Immeuble?> formulaireImmeuble(BuildContext context,
    {Immeuble? existant}) {
  return EcranFormulaire.ouvrir<Immeuble>(
    context,
    EcranFormulaire(
      titre: existant == null ? 'Nouvel immeuble' : 'Modifier l’immeuble',
      initial: existant == null
          ? const {}
          : {
              'name': existant.nom,
              'address': existant.adresse,
              'district': existant.quartier,
              'city': existant.ville,
              'floors_count': existant.nbEtages,
              'declared_apartments_count': existant.nbAppartementsPrevus,
              'description': existant.description,
            },
      messageSucces: existant == null ? 'Immeuble créé' : 'Immeuble modifié',
      champs: const [
        Champ('name', 'Nom',
            obligatoire: true,
            maxLongueur: 150,
            indice: 'Ex. Résidence Almadies'),
        Champ('address', 'Adresse', obligatoire: true, maxLongueur: 255),
        Champ('district', 'Quartier', maxLongueur: 100),
        Champ('city', 'Ville', obligatoire: true, maxLongueur: 100),
        Champ('floors_count', "Nombre d'étages",
            type: TypeChamp.entier, min: 0, max: 300),
        Champ('declared_apartments_count', "Nombre d'appartements prévus",
            type: TypeChamp.entier, min: 0, max: 10000),
        Champ('description', 'Description',
            type: TypeChamp.multiligne, maxLongueur: 5000),
      ],
      envoyer: (corps) async => (existant == null
              ? await sl<CreerImmeuble>()(corps)
              : await sl<ModifierImmeuble>()(existant.id, corps))
          .ouLeve(),
    ),
  );
}
