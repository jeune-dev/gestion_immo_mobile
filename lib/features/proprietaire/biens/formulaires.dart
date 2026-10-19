import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/services.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/sources.dart';

/// Formulaires du patrimoine : champs et contraintes repris du contrat (§ 7–10).
class FormulairesBiens {
  static Future<Map?> immeuble(BuildContext context, {Map<String, dynamic>? existant}) {
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Nouvel immeuble' : 'Modifier l’immeuble',
        initial: existant ?? const {},
        messageSucces: existant == null ? 'Immeuble créé' : 'Immeuble modifié',
        champs: const [
          Champ('name', 'Nom', obligatoire: true, maxLongueur: 150, indice: 'Ex. Résidence Almadies'),
          Champ('address', 'Adresse', obligatoire: true, maxLongueur: 255),
          Champ('district', 'Quartier', maxLongueur: 100),
          Champ('city', 'Ville', obligatoire: true, maxLongueur: 100),
          Champ('floors_count', "Nombre d'étages", type: TypeChamp.entier, min: 0, max: 300),
          Champ('declared_apartments_count', "Nombre d'appartements prévus", type: TypeChamp.entier, min: 0, max: 10000),
          Champ('description', 'Description', type: TypeChamp.multiligne, maxLongueur: 5000),
        ],
        envoyer: (corps) async {
          final r = existant == null
              ? await api.post<Map<String, dynamic>>('/immeubles', body: corps)
              : await api.patch<Map<String, dynamic>>('/immeubles/${existant['id']}', body: corps);
          return r['building'];
        },
      ),
    );
  }

  static Future<Map?> appartement(BuildContext context, {Map<String, dynamic>? existant, Map? immeuble}) {
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Nouvel appartement' : 'Modifier l’appartement',
        initial: existant ??
            {
              if (immeuble != null) 'building_id': immeuble['id'],
              if (immeuble != null) 'building_id__libelle': immeuble['name'],
              'charges_amount': 0,
            },
        messageSucces: existant == null ? 'Appartement créé' : 'Appartement modifié',
        champs: [
          if (existant == null) Champ('building_id', 'Immeuble', type: TypeChamp.entite, obligatoire: true, entite: Sources.immeubles),
          const Champ('number', 'Numéro', obligatoire: true, maxLongueur: 30, indice: 'Ex. A12'),
          const Champ('type', 'Type', type: TypeChamp.selection, referentiel: 'type_appartement', obligatoire: true),
          const Champ('floor', 'Étage', type: TypeChamp.entier, min: -5, max: 300),
          const Champ('rent_amount', 'Loyer mensuel', type: TypeChamp.montant, obligatoire: true),
          const Champ('charges_amount', 'Charges mensuelles', type: TypeChamp.montant),
          const Champ('surface', 'Surface (m²)', type: TypeChamp.decimal, max: 100000),
          const Champ('rooms_count', 'Nombre de pièces', type: TypeChamp.entier, min: 0, max: 100),
          const Champ('charge_coefficient', 'Coefficient de charges', type: TypeChamp.decimal,
              indice: 'Utilisé pour répartir les factures communes « selon coefficient » (1 par défaut).'),
          const Champ('is_furnished', 'Meublé', type: TypeChamp.interrupteur),
          const Champ('description', 'Description', type: TypeChamp.multiligne, maxLongueur: 5000),
        ],
        envoyer: (corps) async {
          final r = existant == null
              ? await api.post<Map<String, dynamic>>('/appartements', body: corps)
              : await api.patch<Map<String, dynamic>>('/appartements/${existant['id']}', body: corps);
          return r['apartment'];
        },
      ),
    );
  }

  static Future<Map?> locataire(BuildContext context, {Map<String, dynamic>? existant}) {
    // Une clé par formulaire : un renvoi après coupure réseau ne crée pas de doublon
    final cle = nouvelleCle();
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Nouveau locataire' : 'Modifier le locataire',
        initial: existant ?? const {'send_invitation': true},
        messageSucces: existant == null ? 'Locataire enregistré' : 'Locataire modifié',
        champs: [
          const Champ('first_name', 'Prénom', obligatoire: true, maxLongueur: 80),
          const Champ('last_name', 'Nom', obligatoire: true, maxLongueur: 80),
          const Champ('phone', 'Téléphone', type: TypeChamp.telephone, obligatoire: true, indice: 'Sert à son activation dans l’application'),
          const Champ('email', 'E-mail', type: TypeChamp.email),
          const Champ('id_document_type', "Pièce d'identité", type: TypeChamp.selection, referentiel: 'type_piece_identite'),
          const Champ('id_document_number', 'Numéro de la pièce', maxLongueur: 60),
          const Champ('notes', 'Notes', type: TypeChamp.multiligne, maxLongueur: 2000),
          if (existant == null) ...const [
            Champ('whatsapp_consent', 'Le locataire accepte de recevoir des messages WhatsApp', type: TypeChamp.interrupteur),
            Champ('send_invitation', "Générer un code d'invitation pour l'application", type: TypeChamp.interrupteur),
          ],
        ],
        envoyer: (corps) async {
          if (existant != null) {
            return (await api.patch<Map<String, dynamic>>('/locataires/${existant['id']}', body: corps))['tenant'];
          }
          return api.post<Map<String, dynamic>>('/locataires', body: corps, idempotence: cle);
        },
      ),
    );
  }

  static Future<Map?> bail(BuildContext context, {Map<String, dynamic>? existant, Map<String, dynamic> initial = const {}}) {
    final cle = nouvelleCle();
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Nouveau bail' : 'Modifier le bail',
        initial: existant ?? {'lease_type': 'habitation', 'periodicity': 'mensuel', 'due_day': 5, ...initial},
        intro: existant == null
            ? const Text('Le bail est créé en brouillon. Réalisez puis soumettez l’état des lieux d’entrée depuis la fiche du bail '
                '(exigé par défaut, voir Règles de gestion), puis activez le bail : les échéances seront générées et la caution ouverte.')
            : null,
        messageSucces: existant == null ? 'Bail créé (brouillon)' : 'Bail modifié',
        champs: [
          if (existant == null) ...[
            Champ('apartment_id', 'Appartement', type: TypeChamp.entite, obligatoire: true, entite: Sources.appartements(statut: 'disponible')),
            Champ('tenant_id', 'Locataire', type: TypeChamp.entite, obligatoire: true, entite: Sources.locataires),
          ],
          const Champ('lease_type', 'Type de bail', type: TypeChamp.selection, referentiel: 'type_bail', obligatoire: true),
          const Champ('start_date', "Date d'entrée", type: TypeChamp.date, obligatoire: true),
          const Champ('end_date', 'Date de fin (facultatif)', type: TypeChamp.date),
          const Champ('rent_amount', 'Loyer', type: TypeChamp.montant, indice: "Vide : loyer de l'appartement"),
          const Champ('charges_amount', 'Charges', type: TypeChamp.montant),
          const Champ('deposit_amount', 'Caution', type: TypeChamp.montant),
          const Champ('periodicity', 'Périodicité', type: TypeChamp.selection, referentiel: 'periodicite', obligatoire: true),
          const Champ('due_day', "Jour d'échéance", type: TypeChamp.entier, min: 1, max: 28),
          const Champ('occupants_count', "Nombre d'occupants", type: TypeChamp.entier, min: 1, max: 50),
          const Champ('notice_period_months', 'Préavis (mois)', type: TypeChamp.entier, min: 0, max: 24),
          const Champ('rent_revision_rule', 'Révision du loyer', type: TypeChamp.multiligne, maxLongueur: 2000),
          const Champ('special_conditions', 'Conditions particulières', type: TypeChamp.multiligne, maxLongueur: 10000),
        ],
        envoyer: (corps) async {
          final r = existant == null
              ? await api.post<Map<String, dynamic>>('/baux', body: corps, idempotence: cle)
              : await api.patch<Map<String, dynamic>>('/baux/${existant['id']}', body: corps);
          return r['lease'];
        },
      ),
    );
  }
}
