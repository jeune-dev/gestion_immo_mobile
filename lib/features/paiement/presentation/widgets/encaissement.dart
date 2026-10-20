import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/sources_bail.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/widgets/sources_echeance.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/encaisser_paiement.dart';

/// Encaissement d'un loyer (§ 12) : espèces ou paiement reçu hors application.
/// Idempotency-Key OBLIGATOIRE : un double envoi n'encaisse jamais deux fois.
/// L'API alloue aux échéances, produit les quittances et le mouvement de caisse.
Future<bool> encaisser(BuildContext context,
    {Bail? bail, Echeance? echeance}) async {
  final cle = nouvelleCle();
  final r = await EcranFormulaire.ouvrir<int>(
    context,
    EcranFormulaire(
      titre: 'Encaisser un loyer',
      intro: const Text(
        "Sans échéance choisie, le montant est imputé aux échéances les plus anciennes. Une quittance est générée pour chaque échéance soldée.",
      ),
      initial: {
        'paid_on': aujourdhui(),
        'method': 'especes',
        if (bail != null) 'lease_id': bail.id,
        if (bail != null)
          'lease_id__libelle':
              '${nomDe(bail.locataire)} · ${bail.reference ?? ''}',
        if (echeance != null) 'rent_schedule_id': echeance.id,
        if (echeance != null)
          'rent_schedule_id__libelle': echeance.libelle ?? '',
        if (echeance != null) 'amount': echeance.reste,
      },
      champs: [
        if (bail == null && echeance == null)
          Champ('lease_id', 'Bail',
              type: TypeChamp.entite, obligatoire: true, entite: sourceBaux()),
        if (bail != null && echeance == null)
          Champ('rent_schedule_id', 'Échéance (facultatif)',
              type: TypeChamp.entite, entite: sourceEcheancesImpayees(bail.id)),
        const Champ('amount', 'Montant reçu',
            type: TypeChamp.montant, obligatoire: true, min: 1),
        const Champ('method', 'Moyen de paiement',
            type: TypeChamp.selection,
            referentiel: 'mode_paiement',
            obligatoire: true),
        const Champ('paid_on', 'Date du paiement',
            type: TypeChamp.date, obligatoire: true),
        const Champ('reference', 'Référence (facultatif)',
            maxLongueur: 40, indice: 'N° de reçu, de chèque ou de transaction'),
        const Champ('comment', 'Commentaire',
            type: TypeChamp.multiligne, maxLongueur: 1000),
      ],
      libelleEnvoi: 'Encaisser',
      envoyer: (corps) async {
        if (echeance?.bailId != null) corps['lease_id'] = echeance!.bailId;
        if (bail != null) corps['lease_id'] = bail.id;
        return (await sl<EncaisserPaiement>()(corps, cle: cle)).ouLeve();
      },
    ),
  );
  if (r != null && context.mounted) {
    afficherSucces(
        context,
        r > 0
            ? 'Paiement enregistré · $r quittance(s) générée(s)'
            : 'Paiement enregistré');
  }
  return r != null;
}
