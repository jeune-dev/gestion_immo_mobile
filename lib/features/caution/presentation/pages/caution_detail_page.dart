import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';
import 'package:gestion_immo_mobile/features/caution/domain/usecases/ajouter_justificatif_caution.dart';
import 'package:gestion_immo_mobile/features/caution/domain/usecases/repondre_contestation.dart';
import 'package:gestion_immo_mobile/features/caution/domain/usecases/restituer_caution.dart';
import 'package:gestion_immo_mobile/features/caution/domain/usecases/retenir_caution.dart';
import 'package:gestion_immo_mobile/features/caution/domain/usecases/verser_caution.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/bloc/caution_bloc.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/bloc/caution_event.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/bloc/caution_state.dart';

class CautionDetailPage extends StatelessWidget {
  final String id;
  const CautionDetailPage({super.key, required this.id});

  Future<void> _mouvement(BuildContext context,
      {required bool versement,
      required Caution c,
      required VoidCallback recharger}) async {
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: versement ? 'Versement de caution' : 'Restitution de caution',
        initial: {
          'occurred_on': aujourdhui(),
          'method': 'especes',
          'amount': versement ? c.resteAVerser : c.solde
        },
        intro: versement ? null : Text('Solde détenu : ${montant(c.solde)}'),
        champs: const [
          Champ('amount', 'Montant',
              type: TypeChamp.montant, obligatoire: true, min: 1),
          Champ('method', 'Moyen',
              type: TypeChamp.selection,
              referentiel: 'mode_paiement',
              obligatoire: true),
          Champ('occurred_on', 'Date', type: TypeChamp.date, obligatoire: true),
          Champ('reference', 'Référence', maxLongueur: 64),
        ],
        messageSucces:
            versement ? 'Versement enregistré' : 'Restitution enregistrée',
        envoyer: (corps) async {
          (versement
                  ? await di.sl<VerserCaution>()(id, corps, cle: cle)
                  : await di.sl<RestituerCaution>()(id, corps, cle: cle))
              .ouLeve();
          return true;
        },
      ),
    );
    if (r != null) recharger();
  }

  /// Retenue : un motif ET au moins un justificatif sont exigés (§ 55.4).
  Future<void> _retenue(BuildContext context, VoidCallback recharger) async {
    final photo = await choisirPhoto(context);
    if (photo == null || !context.mounted) return;
    final docId = await executer(
        context, () => di.sl<AjouterJustificatifCaution>()(id, photo.path));
    if (docId == null || !context.mounted) return;
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Retenue sur caution',
        intro: const Encadre(
            'Justificatif joint. Le locataire est informé et peut contester la retenue.'),
        initial: {'occurred_on': aujourdhui()},
        champs: const [
          Champ('amount', 'Montant retenu',
              type: TypeChamp.montant, obligatoire: true, min: 1),
          Champ('reason', 'Motif',
              type: TypeChamp.selection,
              referentiel: 'motif_retenue',
              obligatoire: true),
          Champ('description', 'Explication',
              type: TypeChamp.multiligne,
              obligatoire: true,
              maxLongueur: 2000,
              indice: '5 caractères minimum'),
          Champ('occurred_on', 'Date', type: TypeChamp.date),
        ],
        libelleEnvoi: 'Enregistrer la retenue',
        messageSucces: 'Retenue enregistrée',
        envoyer: (corps) async {
          (await di.sl<RetenirCaution>()(
                  id,
                  {
                    ...corps,
                    'justification_document_ids': [docId],
                  },
                  cle: cle))
              .ouLeve();
          return true;
        },
      ),
    );
    if (r != null) recharger();
  }

  Future<void> _repondre(
      BuildContext context, MouvementCaution t, VoidCallback recharger) async {
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Répondre à la contestation',
        intro: Text('« ${t.messageContestation ?? ''} »'),
        champs: [
          Champ(
            'outcome',
            'Décision',
            type: TypeChamp.selection,
            obligatoire: true,
            options: [
              for (final o in refs
                  .options('statut_contestation')
                  .where((o) => o.code != 'conteste'))
                OptionRef(o.code, o.label)
            ],
          ),
          Champ('adjusted_amount', 'Nouveau montant retenu',
              type: TypeChamp.montant,
              visible: (v) => v['outcome'] == 'ajustee'),
          const Champ('response', 'Réponse au locataire',
              type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 4000),
        ],
        libelleEnvoi: 'Envoyer la réponse',
        messageSucces: 'Réponse envoyée',
        envoyer: (corps) async {
          (await di.sl<RepondreContestation>()(id, t.id, corps)).ouLeve();
          return true;
        },
      ),
    );
    if (r != null) recharger();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CautionBloc>()..add(LoadCaution(id)),
      child: BlocConsumer<CautionBloc, CautionState>(
        listener: (context, state) {
          if (state is CautionActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is CautionInitial ||
            state is CautionLoading ||
            state is CautionLoaded ||
            state is CautionError,
        builder: (context, state) {
          if (state is CautionLoaded) {
            return _buildFiche(context, state.caution);
          }
          return VueChargement(
            titre: 'Caution',
            failure: state is CautionError ? state.failure : null,
            onReessayer: () => context.read<CautionBloc>().add(LoadCaution(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, Caution c) {
    final bloc = context.read<CautionBloc>();
    return Scaffold(
      appBar: AppBar(title: Text('Caution · ${nomDe(c.locataire)}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(c.bailReference ?? '',
                          style: Theme.of(context).textTheme.titleMedium)),
                  Statut(FamilleStatut.caution, 'statut_caution', c.statut),
                ],
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Ligne('Attendue', montant(c.attendue)),
              Ligne('Reçue', montant(c.recue)),
              Ligne('Retenue', montant(c.retenue)),
              Ligne('Restituée', montant(c.restituee)),
              const Divider(),
              Ligne(
                'Solde détenu',
                null,
                widget: Montant(c.solde,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18)),
              ),
              if (c.restituerAvant != null)
                Ligne('À restituer avant le', date(c.restituerAvant)),
            ],
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (c.resteAVerser > 0)
                FilledButton.icon(
                  onPressed: () => _mouvement(context,
                      versement: true,
                      c: c,
                      recharger: () => bloc.add(RafraichirCaution(id))),
                  icon: const Icon(Icons.add),
                  label: const Text('Enregistrer un versement'),
                ),
              if (c.bailTermine && c.solde > 0) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      _retenue(context, () => bloc.add(RafraichirCaution(id))),
                  icon: const Icon(Icons.remove),
                  label: const Text('Retenue justifiée'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _mouvement(context,
                      versement: false,
                      c: c,
                      recharger: () => bloc.add(RafraichirCaution(id))),
                  icon: const Icon(Icons.undo),
                  label: const Text('Restituer'),
                ),
              ],
            ],
          ),
          if (!c.bailTermine && c.solde > 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Encadre(
                  'Retenues et restitution sont possibles une fois le bail terminé.'),
            ),
          const SizedBox(height: AppTheme.espaceLg),
          Section(
            titre: 'Mouvements',
            padding: false,
            children: [
              if (c.mouvements.isEmpty)
                const ListTile(title: Text('Aucun mouvement')),
              for (final t in c.mouvements)
                ListTile(
                  title: Text(
                    '${refs.libelle('type_mouvement_caution', t.type)}${t.motif != null ? ' · ${refs.libelle('motif_retenue', t.motif)}' : ''}',
                  ),
                  subtitle: Text(
                    [
                      date(t.date),
                      if (t.description != null) t.description!,
                      if (t.statutContestation != null)
                        'Contestation : ${refs.libelle('statut_contestation', t.statutContestation)}',
                    ].join('\n'),
                  ),
                  isThreeLine:
                      t.description != null || t.statutContestation != null,
                  trailing: Montant(t.montant),
                  onTap: t.contestee
                      ? () => _repondre(
                          context, t, () => bloc.add(RafraichirCaution(id)))
                      : null,
                ),
            ],
          ),
          if (c.mouvements.any((t) => t.contestee))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Encadre(
                  'Une retenue est contestée par le locataire : touchez-la pour répondre.',
                  ton: TonStatut.danger),
            ),
          const SizedBox(height: AppTheme.espaceLg),
          SectionDocuments(
              type: 'deposit', ajout: false, id: id, titre: 'Justificatifs'),
        ],
      ),
    );
  }
}
