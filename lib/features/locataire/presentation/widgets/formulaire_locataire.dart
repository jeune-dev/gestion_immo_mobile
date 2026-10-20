import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/entities/locataire.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/usecases/creer_locataire.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/usecases/modifier_locataire.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;

const _champsCommuns = [
  Champ('first_name', 'Prénom', obligatoire: true, maxLongueur: 80),
  Champ('last_name', 'Nom', obligatoire: true, maxLongueur: 80),
  Champ(
    'phone',
    'Téléphone',
    type: TypeChamp.telephone,
    obligatoire: true,
    indice: 'Sert à son activation dans l’application',
  ),
  Champ('email', 'E-mail', type: TypeChamp.email),
  Champ(
    'id_document_type',
    "Pièce d'identité",
    type: TypeChamp.selection,
    referentiel: 'type_piece_identite',
  ),
  Champ('id_document_number', 'Numéro de la pièce', maxLongueur: 60),
  Champ('notes', 'Notes', type: TypeChamp.multiligne, maxLongueur: 2000),
];

/// Nouveau locataire (§ 9), avec code d'invitation si demandé.
Future<LocataireCree?> creerLocataire(BuildContext context) {
  // Une clé par formulaire : un renvoi après coupure réseau ne crée pas de
  // doublon.
  final cle = nouvelleCle();
  return EcranFormulaire.ouvrir<LocataireCree>(
    context,
    EcranFormulaire(
      titre: 'Nouveau locataire',
      initial: const {'send_invitation': true},
      messageSucces: 'Locataire enregistré',
      champs: const [
        ..._champsCommuns,
        Champ(
          'whatsapp_consent',
          'Le locataire accepte de recevoir des messages WhatsApp',
          type: TypeChamp.interrupteur,
        ),
        Champ(
          'send_invitation',
          "Générer un code d'invitation pour l'application",
          type: TypeChamp.interrupteur,
        ),
      ],
      envoyer: (data) async {
        final result = await di.sl<CreerLocataire>()(data, cle: cle);
        return result.ouLeve();
      },
    ),
  );
}

Future<Locataire?> modifierLocataire(
  BuildContext context,
  Locataire existant,
) {
  return EcranFormulaire.ouvrir<Locataire>(
    context,
    EcranFormulaire(
      titre: 'Modifier le locataire',
      initial: {
        'first_name': existant.prenom,
        'last_name': existant.nom,
        'phone': existant.telephone,
        'email': existant.email,
        'id_document_type': existant.typePiece,
        'id_document_number': existant.numeroPiece,
        'notes': existant.notes,
      },
      messageSucces: 'Locataire modifié',
      champs: _champsCommuns,
      envoyer: (data) async {
        final result = await di.sl<ModifierLocataire>()(existant.id, data);
        return result.ouLeve();
      },
    ),
  );
}
