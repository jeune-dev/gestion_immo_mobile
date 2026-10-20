import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/entities/artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/usecases/creer_artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/usecases/modifier_artisan.dart';

/// Création ou modification d'un artisan (§ 24).
Future<Artisan?> formulaireArtisan(BuildContext context, {Artisan? existant}) {
  final cle = nouvelleCle();
  return EcranFormulaire.ouvrir<Artisan>(
    context,
    EcranFormulaire(
      titre: existant == null ? 'Nouvel artisan' : "Modifier l'artisan",
      initial: existant == null
          ? const {}
          : {
              'name': existant.nom,
              'trade': existant.metier,
              'phone': existant.telephone,
              'email': existant.email,
              'notes': existant.notes
            },
      champs: const [
        Champ('name', 'Nom', obligatoire: true, maxLongueur: 150),
        Champ('trade', 'Métier',
            type: TypeChamp.selection,
            referentiel: 'metier_artisan',
            obligatoire: true),
        Champ('phone', 'Téléphone', type: TypeChamp.telephone),
        Champ('email', 'E-mail', type: TypeChamp.email),
        Champ('notes', 'Notes', type: TypeChamp.multiligne, maxLongueur: 2000),
      ],
      messageSucces: existant == null ? 'Artisan ajouté' : 'Artisan modifié',
      envoyer: (c) async => (existant == null
              ? await sl<CreerArtisan>()(c, cle: cle)
              : await sl<ModifierArtisan>()(existant.id, c))
          .ouLeve(),
    ),
  );
}
