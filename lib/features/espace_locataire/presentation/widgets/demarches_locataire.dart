import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/accord_bail.dart'
    show dansLeFutur;
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/accords_locataire.dart';

/// Congé donné par le locataire : date de sortie qui respecte le préavis du bail.
Future<bool> donnerCongeLocataire(
  BuildContext context, {
  required String bailId,
  int? preavisMois,
}) async {
  final preavis = preavisMois ?? 0;
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Donner congé',
      intro: Text(
        preavis > 0
            ? 'Votre bail prévoit un préavis de $preavis mois : vous pouvez partir au plus tôt le ${date(dansLeFutur(mois: preavis))}. '
                  'Votre bailleur est prévenu. Le loyer reste dû jusqu’à votre départ.'
            : 'Votre bailleur est prévenu. Le loyer reste dû jusqu’à votre départ.',
      ),
      initial: {'planned_exit_date': dansLeFutur(mois: preavis)},
      champs: [
        Champ(
          'planned_exit_date',
          'Date de départ prévue',
          type: TypeChamp.date,
          obligatoire: true,
          dateMin: dansLeFutur(mois: preavis),
        ),
        const Champ(
          'reason',
          'Message à votre bailleur (facultatif)',
          type: TypeChamp.multiligne,
          maxLongueur: 1000,
        ),
      ],
      libelleEnvoi: 'Envoyer le congé',
      messageSucces: 'Congé envoyé à votre bailleur',
      envoyer: (c) async => (await sl<ActionLocataire>()(
        'baux/$bailId/conge',
        corps: c,
      )).ouLeve(),
    ),
  );
  return r != null;
}

Future<bool> retirerCongeLocataire(BuildContext context, String bailId) async {
  final ok = await confirmer(
    context,
    titre: 'Retirer mon congé',
    message: 'Votre bail continue normalement et votre bailleur est prévenu.',
    action: 'Retirer',
  );
  if (ok == null || !context.mounted) return false;
  final r = await sl<ActionLocataire>()('baux/$bailId/conge/annuler');
  if (!context.mounted) return false;
  return r.fold(
    (f) {
      afficherErreurApi(context, f);
      return false;
    },
    (_) {
      afficherSucces(context, 'Congé retiré');
      return true;
    },
  );
}

/// Espèces remises au bailleur : déclarées ici, comptées après sa confirmation.
Future<bool> declarerEspeces(
  BuildContext context, {
  required String echeanceId,
  required num reste,
  String? beneficiaire,
}) async {
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'J’ai payé en espèces',
      intro: Text(
        'Indiquez ce que vous avez remis à ${beneficiaire ?? 'votre bailleur'}. '
        'Il reçoit une demande de confirmation : votre échéance sera soldée et votre reçu disponible dès qu’il l’aura validée. '
        'Pas de relance de loyer pendant ce temps.',
      ),
      initial: {'amount': reste, 'paid_on': aujourdhui()},
      champs: [
        Champ(
          'amount',
          'Montant remis',
          type: TypeChamp.montant,
          obligatoire: true,
          min: 1,
        ),
        const Champ(
          'paid_on',
          'Date de la remise',
          type: TypeChamp.date,
          obligatoire: true,
          pasDansLeFutur: true,
        ),
      ],
      libelleEnvoi: 'Signaler la remise',
      messageSucces: 'Remise signalée à votre bailleur',
      envoyer: (c) async => (await sl<ActionLocataire>()(
        'paiements/especes',
        corps: {...c, 'rent_schedule_id': echeanceId},
      )).ouLeve(),
    ),
  );
  return r != null;
}

/// Reçu PDF d'un paiement (partiel compris).
Future<void> ouvrirRecuPaiement(
  BuildContext context,
  String paiementId,
  String? reference,
) => ouvrirPdf(
  context,
  () => sl<GetRecuPaiement>()(paiementId),
  'recu-${reference ?? paiementId}.pdf',
);

/// Le locataire conteste un remboursement (argent non reçu, montant erroné…).
Future<bool> contesterRemboursement(
  BuildContext context,
  String paiementId,
) async {
  final message = await confirmer(
    context,
    titre: 'Contester le remboursement',
    message: 'Expliquez à votre bailleur ce qui ne va pas (argent non reçu, montant différent…). Il doit vous répondre.',
    action: 'Envoyer',
    motif: true,
    libelleMotif: 'Votre message',
    minMotif: 5,
    maxMotif: 2000,
  );
  if (message == null || !context.mounted) return false;
  final r = await sl<ActionLocataire>()(
    'paiements/$paiementId/contester',
    corps: {'message': message},
  );
  if (!context.mounted) return false;
  return r.fold(
    (f) {
      afficherErreurApi(context, f);
      return false;
    },
    (_) {
      afficherSucces(context, 'Contestation envoyée à votre bailleur');
      return true;
    },
  );
}
