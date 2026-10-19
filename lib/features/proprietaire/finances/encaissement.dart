import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/sources.dart';

/// Encaissement d'un loyer (§ 12) : espèces ou paiement reçu hors application.
/// Idempotency-Key OBLIGATOIRE : un double envoi n'encaisse jamais deux fois.
/// L'API alloue aux échéances, produit les quittances et le mouvement de caisse.
Future<Map?> encaisser(BuildContext context, {Map? bail, Map? echeance}) async {
  final cle = nouvelleCle();
  final reste = echeance == null ? null : entier(echeance['amount_due']) - entier(echeance['amount_paid']);
  final r = await EcranFormulaire.ouvrir<Map>(
    context,
    EcranFormulaire(
      titre: 'Encaisser un loyer',
      intro: const Text("Sans échéance choisie, le montant est imputé aux échéances les plus anciennes. Une quittance est générée pour chaque échéance soldée."),
      initial: {
        'paid_on': aujourdhui(),
        'method': 'especes',
        if (bail != null) 'lease_id': bail['id'],
        if (bail != null) 'lease_id__libelle': '${nomComplet(bail['tenant'] as Map?)} · ${bail['reference']}',
        if (echeance != null) 'rent_schedule_id': echeance['id'],
        if (echeance != null) 'rent_schedule_id__libelle': '${echeance['label']}',
        'amount': ?reste,
      },
      champs: [
        if (bail == null && echeance == null) Champ('lease_id', 'Bail', type: TypeChamp.entite, obligatoire: true, entite: Sources.baux()),
        if (bail != null && echeance == null)
          Champ('rent_schedule_id', 'Échéance (facultatif)', type: TypeChamp.entite, entite: Sources.echeancesImpayees('${bail['id']}')),
        const Champ('amount', 'Montant reçu', type: TypeChamp.montant, obligatoire: true, min: 1),
        const Champ('method', 'Moyen de paiement', type: TypeChamp.selection, referentiel: 'mode_paiement', obligatoire: true),
        const Champ('paid_on', 'Date du paiement', type: TypeChamp.date, obligatoire: true),
        const Champ('reference', 'Référence (facultatif)', maxLongueur: 40, indice: 'N° de reçu, de chèque ou de transaction'),
        const Champ('comment', 'Commentaire', type: TypeChamp.multiligne, maxLongueur: 1000),
      ],
      libelleEnvoi: 'Encaisser',
      envoyer: (corps) {
        if (echeance != null) corps['lease_id'] = echeance['lease_id'];
        if (bail != null) corps['lease_id'] = bail['id'];
        return api.post<Map<String, dynamic>>('/paiements/especes', body: corps, idempotence: cle);
      },
    ),
  );
  if (r != null && context.mounted) {
    final quittances = ((r['receipts'] as List?) ?? []).length;
    afficherSucces(context, quittances > 0 ? 'Paiement enregistré · $quittances quittance(s) générée(s)' : 'Paiement enregistré');
  }
  return r;
}
