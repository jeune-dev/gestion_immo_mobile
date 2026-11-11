import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/features/bail/presentation/widgets/accord_bail.dart';

import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/sources_appartement.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/widgets/sources_locataire.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/creer_bail.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/generer_contrat.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/modifier_bail.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/reviser_loyer.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/terminer_bail.dart';

/// Création (brouillon) ou modification d'un bail (§ 10). Renvoie le bail enregistré.
Future<Bail?> formulaireBail(
  BuildContext context, {
  Bail? existant,
  Map<String, dynamic> initial = const {},
}) {
  final cle = nouvelleCle();
  return EcranFormulaire.ouvrir<Bail>(
    context,
    EcranFormulaire(
      titre: existant == null ? 'Nouveau bail' : 'Modifier le bail',
      initial: existant == null
          ? {
              'lease_type': 'habitation',
              'periodicity': 'mensuel',
              'due_day': 5,
              ...initial,
            }
          : {
              'lease_type': existant.typeBail,
              'start_date': existant.debut,
              'end_date': existant.fin,
              'rent_amount': existant.loyer,
              'charges_amount': existant.charges,
              'deposit_amount': existant.montantCaution,
              'periodicity': existant.periodicite,
              'due_day': existant.jourEcheance,
              'occupants_count': existant.nbOccupants,
              'notice_period_months': existant.preavisMois,
              'rent_revision_rule': existant.revisionLoyer,
              'special_conditions': existant.conditionsParticulieres,
            },
      intro: existant == null
          ? const Encadre(
              'Enregistré en brouillon. Vous pourrez ensuite faire l’état des lieux et activer le bail depuis sa fiche.',
            )
          : null,
      messageSucces: existant == null
          ? 'Bail créé (brouillon)'
          : 'Bail modifié',
      champs: [
        if (existant == null) ...[
          Champ(
            'apartment_id',
            'Appartement',
            type: TypeChamp.entite,
            obligatoire: true,
            entite: sourceAppartements(statut: 'disponible'),
            groupe: 'Logement et locataire',
            icone: Icons.apartment_outlined,
          ),
          Champ(
            'tenant_id',
            'Locataire',
            type: TypeChamp.entite,
            obligatoire: true,
            entite: sourceLocataires(),
            icone: Icons.person_outline,
          ),
        ],
        Champ(
          'lease_type',
          'Type de bail',
          type: TypeChamp.selection,
          referentiel: 'type_bail',
          obligatoire: true,
          groupe: existant == null ? null : 'Type de bail',
          icone: Icons.description_outlined,
        ),
        const Champ(
          'start_date',
          "Date d'entrée",
          type: TypeChamp.date,
          obligatoire: true,
          groupe: 'Durée',
          moitie: true,
        ),
        const Champ(
          'end_date',
          'Date de fin',
          apresChamp: 'start_date',
          apresStrict: true,
          type: TypeChamp.date,
          moitie: true,
        ),
        const Champ(
          'rent_amount',
          'Loyer',
          min: 1,
          type: TypeChamp.montant,
          indice: "Si vide : loyer de l'appartement",
          groupe: 'Loyer et paiement',
        ),
        const Champ(
          'charges_amount',
          'Charges',
          type: TypeChamp.montant,
          moitie: true,
        ),
        const Champ(
          'deposit_amount',
          'Caution',
          type: TypeChamp.montant,
          moitie: true,
        ),
        const Champ(
          'periodicity',
          'Périodicité',
          type: TypeChamp.selection,
          referentiel: 'periodicite',
          obligatoire: true,
          moitie: true,
        ),
        const Champ(
          'due_day',
          "Jour d'échéance",
          type: TypeChamp.entier,
          min: 1,
          max: 28,
          moitie: true,
        ),
        const Champ(
          'occupants_count',
          'Occupants',
          type: TypeChamp.entier,
          min: 1,
          max: 50,
          groupe: 'Autres informations',
          moitie: true,
        ),
        const Champ(
          'notice_period_months',
          'Préavis (mois)',
          type: TypeChamp.entier,
          min: 0,
          max: 24,
          moitie: true,
        ),
        const Champ(
          'rent_revision_rule',
          'Révision du loyer',
          type: TypeChamp.multiligne,
          maxLongueur: 2000,
        ),
        const Champ(
          'special_conditions',
          'Conditions particulières',
          type: TypeChamp.multiligne,
          maxLongueur: 10000,
        ),
      ],
      envoyer: (corps) async =>
          (existant == null
                  ? await sl<CreerBail>()(corps, cle: cle)
                  : await sl<ModifierBail>()(existant.id, corps))
              .ouLeve(),
    ),
  );
}

/// Nouveau loyer : proposé au locataire, appliqué aux échéances après son accord.
Future<bool> reviserLoyer(BuildContext context, Bail b) async {
  // Préavis par défaut du serveur (`rent_change_notice_days`) : il refuse une date plus proche.
  final auPlusTot = dansLeFutur(jours: 30);
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      controle: (c) => c['rent_amount'] == null && c['charges_amount'] == null
          ? 'Indiquez le nouveau loyer ou les nouvelles charges.'
          : null,
      titre: 'Proposer un nouveau loyer',
      intro: const Text(
        'Le locataire reçoit la proposition dans son espace. Le nouveau loyer ne s’applique qu’après son accord '
        '(ou l’avenant signé que vous joindrez), à partir de la date d’effet. S’il refuse, le loyer actuel reste.',
      ),
      initial: {
        'rent_amount': b.loyer,
        'charges_amount': b.charges,
        'effective_from': auPlusTot,
      },
      champs: [
        const Champ(
          'rent_amount',
          'Nouveau loyer',
          min: 1,
          type: TypeChamp.montant,
        ),
        const Champ(
          'charges_amount',
          'Nouvelles charges',
          type: TypeChamp.montant,
        ),
        Champ(
          'effective_from',
          "Date d'effet",
          dateMin: auPlusTot,
          type: TypeChamp.date,
          obligatoire: true,
        ),
        const Champ(
          'reason',
          'Motif (révision annuelle, travaux…)',
          type: TypeChamp.multiligne,
          maxLongueur: 1000,
        ),
      ],
      libelleEnvoi: 'Envoyer la proposition',
      messageSucces: 'Proposition envoyée au locataire',
      envoyer: (c) async => (await sl<ReviserLoyer>()(b.id, c)).ouLeve(),
    ),
  );
  return r != null;
}

/// Fin du bail : l'appartement redevient disponible.
Future<bool> terminerBail(BuildContext context, Bail b) async {
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Fin du bail',
      intro: const Text(
        "À faire une fois le locataire parti : l'appartement redevient disponible. La caution sera ensuite restituée ou retenue avant la clôture.",
      ),
      initial: {'ended_on': aujourdhui()},
      champs: [
        Champ(
          'ended_on',
          'Date de sortie',
          dateMin: b.debut,
          type: TypeChamp.date,
          obligatoire: true,
          pasDansLeFutur: true,
        ),
        const Champ(
          'termination_reason',
          'Motif',
          type: TypeChamp.multiligne,
          maxLongueur: 1000,
        ),
      ],
      libelleEnvoi: 'Mettre fin au bail',
      messageSucces: 'Bail terminé',
      envoyer: (c) async => (await sl<TerminerBail>()(b.id, c)).ouLeve(),
    ),
  );
  return r != null;
}

/// Génération du contrat PDF à partir du modèle de bail publié (§ 53).
Future<bool> genererContrat(BuildContext context, Bail b) async {
  final cle = nouvelleCle();
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Générer le contrat',
      intro: const Text(
        'Le contrat est produit en PDF à partir du modèle de bail publié (conforme OHADA) et partagé au locataire.',
      ),
      champs: const [
        Champ(
          'special_clauses',
          'Clauses particulières',
          type: TypeChamp.multiligne,
          maxLongueur: 10000,
        ),
      ],
      libelleEnvoi: 'Générer',
      messageSucces: 'Contrat généré',
      envoyer: (c) async =>
          (await sl<GenererContrat>()(b.id, c, cle: cle)).ouLeve(),
    ),
  );
  return r != null;
}
