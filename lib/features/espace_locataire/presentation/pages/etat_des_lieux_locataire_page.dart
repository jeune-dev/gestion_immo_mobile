import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/telecharger_mon_etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/etat_des_lieux_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/etat_des_lieux_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/etat_des_lieux_locataire_state.dart';

/// État des lieux côté locataire : consulter, accepter ou contester dans le délai (§ 52).
class EtatDesLieuxLocatairePage extends StatelessWidget {
  final String id;
  const EtatDesLieuxLocatairePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<EtatDesLieuxLocataireBloc>()
        ..add(LoadEtatDesLieuxLocataire(id)),
      child:
          BlocConsumer<EtatDesLieuxLocataireBloc, EtatDesLieuxLocataireState>(
        listener: (context, state) {
          if (state is EtatDesLieuxLocataireSuccess) {
            afficherSucces(context, state.message);
          } else if (state is EtatDesLieuxLocataireActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is EtatDesLieuxLocataireInitial ||
            state is EtatDesLieuxLocataireLoading ||
            state is EtatDesLieuxLocataireLoaded ||
            state is EtatDesLieuxLocataireError,
        builder: (context, state) {
          if (state is EtatDesLieuxLocataireLoaded) {
            return _buildFiche(context, state.etatDesLieux);
          }
          return VueChargement(
            titre: 'État des lieux',
            failure: state is EtatDesLieuxLocataireError ? state.failure : null,
            onReessayer: () => context
                .read<EtatDesLieuxLocataireBloc>()
                .add(LoadEtatDesLieuxLocataire(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, EtatDesLieux e) {
    final bloc = context.read<EtatDesLieuxLocataireBloc>();
    final aRepondre = e.statut == 'soumis';
    return Scaffold(
      appBar: AppBar(
        title: Text(refs.libelle('type_etat_des_lieux', e.type)),
        actions: [
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => ouvrirPdf(
                context,
                () => di.sl<TelechargerMonEtatDesLieux>()(id),
                'etat-des-lieux-${e.type}-v${e.version}.pdf'),
          ),
        ],
      ),
      bottomNavigationBar: aRepondre
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final texte = await confirmer(
                            context,
                            titre: "Contester l'état des lieux",
                            message:
                                'Expliquez précisément ce qui ne correspond pas (10 caractères minimum).',
                            motif: true,
                            libelleMotif: 'Votre commentaire',
                            minMotif: 10,
                            danger: true,
                            action: 'Contester',
                          );
                          if (texte != null) {
                            bloc.add(ContesterEtatDesLieuxEvent(id, texte));
                          }
                        },
                        child: const Text('Contester'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final ok = await confirmer(
                            context,
                            titre: "Accepter l'état des lieux",
                            message:
                                'Vous confirmez que ce document correspond à l’état du logement.',
                            action: 'Accepter',
                          );
                          if (ok != null) {
                            bloc.add(AccepterEtatDesLieuxEvent(id));
                          }
                        },
                        child: const Text('Accepter'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (aRepondre) ...[
            Encadre(
                'Sans réponse avant le ${dateHeure(e.limiteReponse)}, il sera considéré comme accepté.',
                ton: TonStatut.avertissement),
            const SizedBox(height: 12),
          ],
          Section(
            children: [
              Ligne('Statut', null,
                  widget: Statut(FamilleStatut.etatDesLieux,
                      'statut_etat_des_lieux', e.statut)),
              Ligne('Date', date(e.realiseLe)),
              Ligne('Compteur d’eau',
                  e.compteurEau == null ? null : '${e.compteurEau} m³'),
              Ligne(
                  'Compteur d’électricité',
                  e.compteurElectricite == null
                      ? null
                      : '${e.compteurElectricite} kWh'),
              Ligne('Clés', e.nbCles == null ? null : '${e.nbCles}'),
              if (e.observations != null) Ligne('Observations', e.observations),
              if (e.contestation != null)
                Ligne('Votre contestation', e.contestation),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in e.pieces)
            Card(
              child: ExpansionTile(
                title: Text(p.nom),
                children: [
                  for (final it in p.elements)
                    ListTile(
                      dense: true,
                      title: Text(
                          refs.libelle('element_etat_des_lieux', it.element)),
                      subtitle:
                          it.commentaire == null ? null : Text(it.commentaire!),
                      trailing: Text(refs.libelle('etat_element', it.etat)),
                      onTap: it.photos.isEmpty
                          ? null
                          : () => afficherImage(
                              context, it.photos.first.document.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
