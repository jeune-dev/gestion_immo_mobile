import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/action_bail.dart';

/// Date ISO à `jours` jours (ou `mois` mois) d'aujourd'hui.
String dansLeFutur({int jours = 0, int mois = 0}) {
  final d = DateTime.now();
  final cible = DateTime(d.year, d.month + mois, d.day + jours);
  return '${cible.year.toString().padLeft(4, '0')}-'
      '${cible.month.toString().padLeft(2, '0')}-'
      '${cible.day.toString().padLeft(2, '0')}';
}

Future<bool> _executer(
  BuildContext context,
  Future<void> Function() action,
  String succes,
) async {
  try {
    await action();
    if (context.mounted) afficherSucces(context, succes);
    return true;
  } on Object catch (e) {
    if (context.mounted) afficherErreurApi(context, e);
    return false;
  }
}

/// Présente le brouillon au locataire, qui l'accepte ou le refuse dans son espace.
Future<bool> proposerBail(BuildContext context, Bail b) async {
  final ok = await confirmer(
    context,
    titre: 'Proposer le bail au locataire',
    message:
        'Le locataire reçoit le bail dans son espace et l’accepte ou le refuse. '
        'Vous pourrez l’activer après son accord. S’il n’a pas l’application, '
        'faites-lui signer le bail et joignez-en la photo.',
    action: 'Proposer',
  );
  if (ok == null || !context.mounted) return false;
  return _executer(
    context,
    () async => (await sl<ActionBail>()(b.id, 'proposer')).ouLeve(),
    'Bail proposé au locataire',
  );
}

/// Photo du document signé par le locataire (bail ou avenant).
Future<bool> joindreSigne(
  BuildContext context,
  Bail b, {
  required String chemin,
  required String succes,
}) async {
  final photo = await choisirPhoto(context);
  if (photo == null || !context.mounted) return false;
  return _executer(
    context,
    () async =>
        (await sl<ActionBail>()(b.id, chemin, fichier: photo.path)).ouLeve(),
    succes,
  );
}

/// Congé donné par le propriétaire : date qui respecte le préavis, motif.
Future<bool> donnerConge(BuildContext context, Bail b) async {
  final preavis = b.preavisMois ?? 0;
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Donner congé',
      intro: Text(
        preavis > 0
            ? 'Le préavis du bail est de $preavis mois : la sortie ne peut pas être avant le ${date(dansLeFutur(mois: preavis))}. '
                  'Le locataire est prévenu. Vous terminerez le bail le jour de son départ.'
            : 'Le locataire est prévenu. Vous terminerez le bail le jour de son départ.',
      ),
      initial: {'planned_exit_date': dansLeFutur(mois: preavis)},
      champs: [
        Champ(
          'planned_exit_date',
          'Date de sortie prévue',
          type: TypeChamp.date,
          obligatoire: true,
          dateMin: dansLeFutur(mois: preavis),
        ),
        const Champ(
          'reason',
          'Motif du congé',
          type: TypeChamp.multiligne,
          obligatoire: true,
          minLongueur: 3,
          maxLongueur: 1000,
        ),
      ],
      libelleEnvoi: 'Envoyer le congé',
      messageSucces: 'Congé envoyé au locataire',
      envoyer: (c) async =>
          (await sl<ActionBail>()(b.id, 'conge', corps: c)).ouLeve(),
    ),
  );
  return r != null;
}

Future<bool> retirerConge(BuildContext context, Bail b) async {
  final ok = await confirmer(
    context,
    titre: 'Retirer le congé',
    message: 'Le bail continue normalement et le locataire est prévenu.',
    action: 'Retirer',
  );
  if (ok == null || !context.mounted) return false;
  return _executer(
    context,
    () async => (await sl<ActionBail>()(b.id, 'conge/annuler')).ouLeve(),
    'Congé retiré',
  );
}

Future<bool> retirerAvenant(
  BuildContext context,
  Bail b,
  AvenantLoyer a,
) async {
  final ok = await confirmer(
    context,
    titre: 'Retirer la proposition',
    message: 'Le loyer actuel reste en vigueur et le locataire est prévenu.',
    action: 'Retirer',
  );
  if (ok == null || !context.mounted) return false;
  return _executer(
    context,
    () async =>
        (await sl<ActionBail>()(b.id, 'avenants/${a.id}/annuler')).ouLeve(),
    'Proposition retirée',
  );
}

/// État de l'accord du locataire et ce qui reste à faire, en tête de fiche.
class SectionAccordBail extends StatelessWidget {
  final Bail bail;
  final VoidCallback recharger;
  const SectionAccordBail({
    super.key,
    required this.bail,
    required this.recharger,
  });

  Bail get b => bail;

  @override
  Widget build(BuildContext context) {
    if (b.statut == 'brouillon') return _brouillon(context);
    if (b.statut == 'actif') return _actif(context);
    return const SizedBox.shrink();
  }

  Widget _brouillon(BuildContext context) {
    final (texte, ton) = b.accepteLe != null
        ? (
            b.modeAccord == 'papier'
                ? 'Bail signé sur papier, joint le ${date(b.accepteLe)}. Vous pouvez l’activer.'
                : 'Accepté par le locataire le ${date(b.accepteLe)}. Vous pouvez l’activer.',
            TonStatut.succes,
          )
        : b.refuseLe != null
        ? (
            'Refusé le ${date(b.refuseLe)}${b.motifRefus == null ? '' : ' : « ${b.motifRefus} »'}. Modifiez le bail puis proposez-le à nouveau.',
            TonStatut.danger,
          )
        : b.proposeLe != null
        ? (
            'Proposé le ${date(b.proposeLe)}, en attente de la réponse du locataire.',
            TonStatut.avertissement,
          )
        : (
            'Le locataire doit accepter le bail avant son activation : proposez-le dans son espace, ou joignez le bail signé.',
            TonStatut.info,
          );
    return Section(
      titre: 'Accord du locataire',
      children: [
        Encadre(texte, ton: ton),
        if (b.accepteLe == null) ...[
          const SizedBox(height: 12),
          TuileOption(
            icone: Icons.send_outlined,
            titre: b.proposeLe == null || b.refuseLe != null
                ? 'Proposer au locataire'
                : 'Proposer à nouveau',
            detail: 'Il accepte ou refuse dans son espace',
            onTap: () async {
              if (await proposerBail(context, b)) recharger();
            },
          ),
          TuileOption(
            icone: Icons.photo_camera_outlined,
            titre: 'Joindre le bail signé',
            detail: 'Photo du bail signé par le locataire',
            onTap: () async {
              if (await joindreSigne(
                context,
                b,
                chemin: 'acceptation-papier',
                succes: 'Bail signé enregistré',
              )) {
                recharger();
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _actif(BuildContext context) {
    final avenant = b.avenantEnAttente;
    final conge = b.sortiePrevue != null;
    if (avenant == null && !conge) return const SizedBox.shrink();
    return Section(
      titre: 'En cours',
      children: [
        if (avenant != null) ...[
          Encadre(
            'Nouveau loyer proposé : ${montant(avenant.total)} par mois à partir du ${date(avenant.dateEffet)} '
            '(au lieu de ${montant(avenant.totalAvant)}). En attente de la réponse du locataire.',
            ton: TonStatut.avertissement,
          ),
          const SizedBox(height: 12),
          TuileOption(
            icone: Icons.photo_camera_outlined,
            titre: 'Joindre l’avenant signé',
            detail: 'Le nouveau loyer s’applique aussitôt',
            onTap: () async {
              if (await joindreSigne(
                context,
                b,
                chemin: 'avenants/${avenant.id}/acceptation-papier',
                succes: 'Avenant signé : nouveau loyer appliqué',
              )) {
                recharger();
              }
            },
          ),
          TuileOption(
            icone: Icons.undo,
            titre: 'Retirer la proposition',
            onTap: () async {
              if (await retirerAvenant(context, b, avenant)) recharger();
            },
          ),
        ],
        if (conge) ...[
          if (avenant != null) const SizedBox(height: 12),
          Encadre(
            '${b.congePar == 'locataire' ? 'Le locataire a donné congé' : 'Vous avez donné congé'} : '
            'sortie prévue le ${date(b.sortiePrevue)}.'
            '${b.motifConge == null || b.motifConge!.isEmpty ? '' : ' Motif : ${b.motifConge}'}',
            ton: TonStatut.info,
          ),
          if (b.congePar == 'proprietaire') ...[
            const SizedBox(height: 12),
            TuileOption(
              icone: Icons.undo,
              titre: 'Retirer le congé',
              onTap: () async {
                if (await retirerConge(context, b)) recharger();
              },
            ),
          ],
        ],
      ],
    );
  }
}
