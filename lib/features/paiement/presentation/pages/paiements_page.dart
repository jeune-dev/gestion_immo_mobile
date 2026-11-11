import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/features/paiement/domain/usecases/recu_et_contestation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/quittance/presentation/widgets/tuile_quittance.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/get_paiements.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/rembourser_paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/paiement_bloc.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/paiement_event.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/paiement_state.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Paiements de loyer reçus (§ 12), avec remboursement.
class PaiementsPage extends StatefulWidget {
  const PaiementsPage({super.key});

  @override
  State<PaiementsPage> createState() => _PaiementsPageState();
}

class _PaiementsPageState extends State<PaiementsPage> {
  final _liste = GlobalKey<ListePagineeState<Paiement>>();
  String _methode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Paiements reçus'),
      ),
      body: Column(
        children: [
          Filtres(
            options: [
              ('', 'Tous'),
              for (final o in refs.options('mode_paiement')) (o.code, o.label),
            ],
            valeur: _methode,
            onChange: (v) => setState(() => _methode = v),
          ),
          Expanded(
            child: ListePaginee<Paiement>(
              key: _liste,
              cle: _methode,
              vide: 'Aucun paiement',
              charger: (page) => di.sl<GetPaiements>()(
                page: page,
                moyen: _methode.isEmpty ? null : _methode,
              ),
              element: (context, p) => TuileOption(
                icone: Icons.check_circle_outline,
                titre: '${nomDe(p.locataire)} · ${p.logementNumero ?? ''}',
                detail:
                    '${date(p.payeLe)} · ${refs.libelle('mode_paiement', p.moyen)} · ${p.reference ?? ''}',
                fin: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Montant(
                      p.montant,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Statut(FamilleStatut.paiement, 'statut_paiement', p.statut),
                  ],
                ),
                onTap: () async {
                  await ouvrir(context, PaiementDetailPage(id: p.id));
                  _liste.currentState?.recharger();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaiementDetailPage extends StatelessWidget {
  final String id;
  const PaiementDetailPage({super.key, required this.id});

  Future<void> _rembourser(BuildContext context, VoidCallback recharger) async {
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Rembourser le paiement',
        intro: const Text(
          'Les échéances concernées sont rouvertes et les quittances annulées.',
        ),
        champs: const [
          Champ(
            'reason',
            'Motif',
            type: TypeChamp.multiligne,
            obligatoire: true,
            minLongueur: 3,
            maxLongueur: 500,
          ),
          Champ(
            'method',
            'Moyen du remboursement',
            type: TypeChamp.selection,
            referentiel: 'mode_paiement',
          ),
        ],
        libelleEnvoi: 'Rembourser',
        messageSucces: 'Paiement remboursé',
        envoyer: (c) async =>
            (await di.sl<RembourserPaiement>()(id, c, cle: cle)).ouLeve(),
      ),
    );
    if (r != null) recharger();
  }

  Future<void> _repondre(BuildContext context, VoidCallback recharger) async {
    final reponse = await confirmer(
      context,
      titre: 'Répondre au locataire',
      message: 'Expliquez comment le remboursement a été fait (date, moyen, preuve). Le locataire reçoit votre réponse.',
      action: 'Envoyer',
      motif: true,
      libelleMotif: 'Votre réponse',
      maxMotif: 2000,
    );
    if (reponse == null || !context.mounted) return;
    final r = await di.sl<RepondreContestationPaiement>()(id, reponse);
    if (!context.mounted) return;
    r.fold((f) => afficherErreurApi(context, f), (_) {
      afficherSucces(context, 'Réponse envoyée au locataire');
      recharger();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<PaiementBloc>()..add(LoadPaiement(id)),
      child: BlocConsumer<PaiementBloc, PaiementState>(
        listener: (context, state) {
          if (state is PaiementActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is PaiementInitial ||
            state is PaiementLoading ||
            state is PaiementLoaded ||
            state is PaiementError,
        builder: (context, state) {
          if (state is PaiementLoaded) {
            return _buildFiche(context, state.fiche);
          }
          return VueChargement(
            titre: 'Paiement',
            failure: state is PaiementError ? state.failure : null,
            onReessayer: () =>
                context.read<PaiementBloc>().add(LoadPaiement(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, FichePaiement fiche) {
    final bloc = context.read<PaiementBloc>();
    final p = fiche.paiement;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(p.reference ?? 'Paiement'),
        actions: [
          MenuActions(
            actions: [
              (
                'Voir le reçu',
                () => ouvrirPdf(
                  context,
                  () => di.sl<GetRecuPaiementProprietaire>()(id),
                  'recu-${p.reference ?? id}.pdf',
                ),
                false,
              ),
              if (p.contestation == 'conteste')
                (
                  'Répondre au locataire',
                  () => _repondre(
                    context,
                    () => bloc.add(RafraichirPaiement(id)),
                  ),
                  false,
                ),
              if (p.statut == 'valide')
                (
                  'Rembourser',
                  () => _rembourser(
                    context,
                    () => bloc.add(RafraichirPaiement(id)),
                  ),
                  true,
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EnTeteFiche(
            surtitre: refs.libelle('mode_paiement', p.moyen),
            titre: montant(p.montant),
            detail: nomDe(p.locataire),
            statut: Statut(FamilleStatut.paiement, 'statut_paiement', p.statut),
          ),
          if (p.contestation != null) ...[
            const SizedBox(height: AppTheme.espaceLg),
            Encadre(
              p.contestation == 'conteste'
                  ? 'Le locataire conteste ce remboursement : « ${p.messageContestation ?? ''} ». Répondez-lui depuis le menu.'
                  : 'Contestation du locataire : « ${p.messageContestation ?? ''} ». Votre réponse : « ${p.reponseContestation ?? ''} »',
              ton: p.contestation == 'conteste'
                  ? TonStatut.avertissement
                  : TonStatut.info,
            ),
          ],
          const SizedBox(height: AppTheme.espaceLg),
          Section(
            titre: 'Informations',
            children: [
              Ligne('Locataire', nomDe(p.locataire)),
              Ligne('Moyen', refs.libelle('mode_paiement', p.moyen)),
              Ligne('Payé le', date(p.payeLe)),
              Ligne('Référence', p.reference ?? ''),
              if (p.commentaire != null) Ligne('Commentaire', p.commentaire),
              if (p.rembourseLe != null) ...[
                Ligne('Remboursé le', dateHeure(p.rembourseLe)),
                Ligne('Motif', p.motifRemboursement ?? ''),
              ],
            ],
          ),
          if (p.imputations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Section(
              titre: 'Imputation',
              children: [
                for (final a in p.imputations)
                  Ligne(a.libelle, montant(a.montant)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Section(
            titre: 'Quittances',
            padding: false,
            children: [
              if (fiche.quittances.isEmpty)
                const ListTile(
                  title: Text('Aucune quittance (échéance pas encore soldée)'),
                ),
              for (final q in fiche.quittances) TuileQuittance(q: q),
            ],
          ),
        ],
      ),
    );
  }
}
