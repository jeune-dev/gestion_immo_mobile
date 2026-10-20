import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/cautions_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/cautions_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/cautions_locataire_state.dart';

/// Ma caution (§ 55) : montants et contestation d'une retenue.
class CautionLocatairePage extends StatelessWidget {
  const CautionLocatairePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<CautionsLocataireBloc>()..add(LoadCautionsLocataire()),
      child: BlocConsumer<CautionsLocataireBloc, CautionsLocataireState>(
        listener: (context, state) {
          if (state is CautionsLocataireSuccess) {
            afficherSucces(context, state.message);
          } else if (state is CautionsLocataireActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is CautionsLocataireInitial ||
            state is CautionsLocataireLoading ||
            state is CautionsLocataireLoaded ||
            state is CautionsLocataireError,
        builder: (context, state) {
          if (state is CautionsLocataireLoaded) {
            return _buildFiche(context, state.cautions);
          }
          return VueChargement(
            titre: 'Ma caution',
            failure: state is CautionsLocataireError ? state.failure : null,
            onReessayer: () => context
                .read<CautionsLocataireBloc>()
                .add(LoadCautionsLocataire()),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, List<Caution> cautions) {
    final bloc = context.read<CautionsLocataireBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ma caution')),
      body: cautions.isEmpty
          ? const Vide('Aucune caution', icone: Icons.savings_outlined)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final c in cautions) ...[
                  Section(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('Bail ${c.bailReference ?? ''}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          Statut(FamilleStatut.caution, 'statut_caution',
                              c.statut),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Ligne('Montant prévu', montant(c.attendue)),
                      Ligne('Versé', montant(c.recue)),
                      Ligne('Retenu', montant(c.retenue)),
                      Ligne('Restitué', montant(c.restituee)),
                      Ligne('Détenu par le propriétaire', montant(c.solde)),
                    ],
                  ),
                  for (final t
                      in c.mouvements.where((t) => t.type == 'retenue'))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Retenue de ${montant(t.montant)} · ${refs.libelle('motif_retenue', t.motif)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (t.description != null) Text(t.description!),
                            if (t.statutContestation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Contestation : ${refs.libelle('statut_contestation', t.statutContestation)}'
                                  '${t.reponseProprietaire != null ? '\nRéponse : ${t.reponseProprietaire}' : ''}',
                                ),
                              )
                            else
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () async {
                                    final msg = await confirmer(
                                      context,
                                      titre: 'Contester la retenue',
                                      message:
                                          'Expliquez pourquoi vous contestez (10 caractères minimum). La caution passe en litige.',
                                      motif: true,
                                      minMotif: 10,
                                      libelleMotif: 'Votre message',
                                      action: 'Contester',
                                    );
                                    if (msg != null) {
                                      bloc.add(
                                          ContesterRetenueEvent(t.id, msg));
                                    }
                                  },
                                  child: const Text('Contester cette retenue'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}
