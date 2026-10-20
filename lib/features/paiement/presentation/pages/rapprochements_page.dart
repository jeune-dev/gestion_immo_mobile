import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/sources_bail.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/widgets/sources_echeance.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/get_rapprochements.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/rejeter_rapprochement.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/resoudre_rapprochement.dart';

/// File « À rapprocher » (§ 51.3) : paiements non identifiés et excédents.
class RapprochementsPage extends StatefulWidget {
  const RapprochementsPage({super.key});

  @override
  State<RapprochementsPage> createState() => _RapprochementsPageState();
}

class _RapprochementsPageState extends State<RapprochementsPage> {
  final _liste = GlobalKey<ListePagineeState<Rapprochement>>();
  String _statut = 'en_attente';

  Future<void> _traiter(Rapprochement e) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(e.type == 'excedent'
                  ? 'Imputer le crédit à une échéance'
                  : 'Rattacher à un bail'),
              onTap: () => Navigator.pop(ctx, 'resoudre'),
            ),
            ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Rejeter et rembourser'),
                onTap: () => Navigator.pop(ctx, 'rejeter')),
          ],
        ),
      ),
    );
    if (choix == null || !mounted) return;
    final Object? r;
    if (choix == 'resoudre') {
      final cle = nouvelleCle();
      r = await EcranFormulaire.ouvrir<Object>(
        context,
        EcranFormulaire(
          titre: 'Rapprocher le paiement',
          intro: Text(
              '${montant(e.montant)} — ${refs.libelle('type_rapprochement', e.type)}'),
          initial: {if (e.bailId != null) 'lease_id': e.bailId},
          champs: [
            if (e.bailId == null)
              Champ('lease_id', 'Bail',
                  type: TypeChamp.entite,
                  obligatoire: true,
                  entite: sourceBaux()),
            if (e.bailId != null)
              Champ('rent_schedule_id', 'Échéance (facultatif)',
                  type: TypeChamp.entite,
                  entite: sourceEcheancesImpayees(e.bailId!)),
            const Champ('note', 'Note',
                type: TypeChamp.multiligne, maxLongueur: 1000),
          ],
          libelleEnvoi: 'Rapprocher',
          messageSucces: 'Paiement rapproché',
          envoyer: (c) async =>
              (await sl<ResoudreRapprochement>()(e.id, c, cle: cle)).ouLeve(),
        ),
      );
    } else {
      r = await EcranFormulaire.ouvrir<Object>(
        context,
        EcranFormulaire(
          titre: 'Rejeter et rembourser',
          initial: const {'refund_method': 'especes'},
          champs: const [
            Champ('note', 'Motif',
                type: TypeChamp.multiligne,
                obligatoire: true,
                maxLongueur: 1000),
            Champ('refund_method', 'Moyen du remboursement',
                type: TypeChamp.selection, referentiel: 'mode_paiement'),
          ],
          libelleEnvoi: 'Rejeter',
          messageSucces: 'Paiement rejeté',
          envoyer: (c) async =>
              (await sl<RejeterRapprochement>()(e.id, c)).ouLeve(),
        ),
      );
    }
    if (r != null) _liste.currentState?.recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À rapprocher')),
      body: Column(
        children: [
          Filtres(
            options: [
              for (final o in refs.options('statut_rapprochement'))
                (o.code, o.label)
            ],
            valeur: _statut,
            onChange: (v) => setState(() => _statut = v),
          ),
          Expanded(
            child: ListePaginee<Rapprochement>(
              key: _liste,
              cle: _statut,
              vide: 'Rien à rapprocher',
              iconeVide: Icons.verified_outlined,
              charger: (page) =>
                  sl<GetRapprochements>()(page: page, statut: _statut),
              element: (context, e) => ListTile(
                title: Text(refs.libelle('type_rapprochement', e.type)),
                subtitle: Text(
                  [
                    if (e.locataire != null) e.locataire!.nomComplet,
                    if (e.telephonePayeur != null) e.telephonePayeur!,
                    if (e.referenceRecue != null) 'Réf. ${e.referenceRecue}',
                    dateHeure(e.creeLe),
                  ].join(' · '),
                ),
                trailing: Montant(e.montant,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: e.statut == 'en_attente' ? () => _traiter(e) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
