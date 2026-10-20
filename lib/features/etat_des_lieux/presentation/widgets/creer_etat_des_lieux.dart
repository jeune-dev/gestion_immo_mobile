import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/sources_bail.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/usecases/creer_etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/pages/etat_des_lieux_detail_page.dart';

/// Crée un état des lieux (brouillon, pièces types pré-remplies) puis l'ouvre.
Future<EtatDesLieux?> creerEtatDesLieux(BuildContext context,
    {String? bailId, String? type}) async {
  final cle = nouvelleCle();
  final r = await EcranFormulaire.ouvrir<EtatDesLieux>(
    context,
    EcranFormulaire(
      titre: 'Nouvel état des lieux',
      initial: {if (type != null) 'type': type, 'performed_at': aujourdhui()},
      intro: const Text(
          'Les pièces usuelles sont proposées automatiquement selon le type de logement ; vous pourrez en ajouter.'),
      champs: [
        if (bailId == null)
          Champ(
            'lease_id',
            'Bail',
            type: TypeChamp.entite,
            obligatoire: true,
            entite: sourceBaux(statut: ''),
          ),
        const Champ('type', 'Type',
            type: TypeChamp.selection,
            referentiel: 'type_etat_des_lieux',
            obligatoire: true),
        const Champ('performed_at', 'Date de la visite', type: TypeChamp.date),
      ],
      libelleEnvoi: 'Créer',
      envoyer: (c) async => (await sl<CreerEtatDesLieux>()(
              {...c, if (bailId != null) 'lease_id': bailId},
              cle: cle))
          .ouLeve(),
    ),
  );
  if (r != null && context.mounted) {
    await ouvrir(context, EtatDesLieuxDetailPage(id: r.id));
  }
  return r;
}
