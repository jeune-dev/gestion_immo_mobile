import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/parametres/domain/entities/parametres.dart';
import 'package:gestion_immo_mobile/features/parametres/presentation/bloc/parametres_bloc.dart';
import 'package:gestion_immo_mobile/features/parametres/presentation/bloc/parametres_event.dart';
import 'package:gestion_immo_mobile/features/parametres/presentation/bloc/parametres_state.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Règles de gestion du propriétaire (relances § 14, état des lieux § 52.4, caution § 55, canaux § 54.3).
class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  static const _delais = [-7, -3, -1, 0, 1, 3, 7, 15, 30];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ParametresBloc>()..add(LoadParametres()),
      child: BlocConsumer<ParametresBloc, ParametresState>(
        listener: (context, state) {
          if (state is ParametresSuccess) {
            afficherSucces(context, state.message);
          } else if (state is ParametresActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is ParametresInitial ||
            state is ParametresLoading ||
            state is ParametresLoaded ||
            state is ParametresError,
        builder: (context, state) {
          if (state is ParametresLoaded) {
            return _buildFiche(context, state.parametres);
          }
          return VueChargement(
            titre: 'Règles de gestion',
            failure: state is ParametresError ? state.failure : null,
            onReessayer: () =>
                context.read<ParametresBloc>().add(LoadParametres()),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, ParametresProprietaire p) {
    final bloc = context.read<ParametresBloc>();
    void maj(Map<String, dynamic> corps) =>
        bloc.add(ModifierReglagesEvent(corps));
    final s = p.reglages;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Règles de gestion'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _relances(context, s, maj),
          const SizedBox(height: 16),
          _delaisDeGestion(context, s, maj),
          const SizedBox(height: 16),
          _politiqueEdlEntree(s, maj),
          const SizedBox(height: 16),
          _canaux(context, s, maj),
        ],
      ),
    );
  }

  /// Jours de relance autour de l'échéance (au moins un).
  Widget _relances(
    BuildContext context,
    ReglagesGestion s,
    ValueChanged<Map<String, dynamic>> maj,
  ) {
    final relances = s.relances.toSet();
    String libelleDelai(int j) => j < 0
        ? 'J$j'
        : j == 0
        ? 'Jour J'
        : 'J+$j';
    return Section(
      titre: 'Relances automatiques de loyer',
      children: [
        const Text(
          'Le locataire est relancé avant et après la date d’échéance aux jours choisis.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final j in _delais)
              FilterChip(
                label: Text(libelleDelai(j)),
                selected: relances.contains(j),
                onSelected: (v) {
                  final n = {...relances};
                  v ? n.add(j) : n.remove(j);
                  if (n.isEmpty) {
                    return afficherErreur(
                      context,
                      'Gardez au moins une relance',
                    );
                  }
                  maj({'reminder_offsets': (n.toList()..sort())});
                },
              ),
          ],
        ),
      ],
    );
  }

  /// Délais en jours : préavis, grâce, réponse à l'état des lieux, caution.
  Widget _delaisDeGestion(
    BuildContext context,
    ReglagesGestion s,
    ValueChanged<Map<String, dynamic>> maj,
  ) {
    final delais = [
      (
        titre: 'Préavis avant échéance',
        detail:
            '${s.preavisEcheance ?? '—'} jour(s) avant, l’échéance passe « À payer »',
        cle: 'schedule_notice_days',
        saisie: 'Préavis (jours)',
        valeur: s.preavisEcheance,
        min: 0,
        max: 30,
      ),
      (
        titre: 'Délai de grâce',
        detail: '« En retard » ${s.delaiGrace ?? '—'} jour(s) après l’échéance',
        cle: 'late_grace_days',
        saisie: 'Délai de grâce (jours)',
        valeur: s.delaiGrace,
        min: 0,
        max: 30,
      ),
      (
        titre: "Délai de réponse à l'état des lieux",
        detail: '${s.delaiReponseEdl ?? '—'} jour(s), puis acceptation tacite',
        cle: 'inspection_response_days',
        saisie: 'Délai de réponse (jours)',
        valeur: s.delaiReponseEdl,
        min: 1,
        max: 60,
      ),
      (
        titre: 'Restitution de la caution',
        detail:
            'Sous ${s.delaiRestitutionCaution ?? '—'} jour(s) après la fin du bail',
        cle: 'deposit_refund_days',
        saisie: 'Délai de restitution (jours)',
        valeur: s.delaiRestitutionCaution,
        min: 1,
        max: 180,
      ),
    ];
    return Card(
      child: Column(
        children: [
          for (final d in delais)
            TuileOption(
              sansMarge: true,
              icone: Icons.tune,
              titre: d.titre,
              detail: d.detail,
              onTap: () async {
                final r = await _saisirEntier(
                  context,
                  cle: d.cle,
                  titre: d.saisie,
                  valeur: d.valeur,
                  min: d.min,
                  max: d.max,
                );
                if (r != null) maj(r);
              },
            ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _saisirEntier(
    BuildContext context, {
    required String cle,
    required String titre,
    required int? valeur,
    required int min,
    required int max,
  }) => EcranFormulaire.ouvrir<Map<String, dynamic>>(
    context,
    EcranFormulaire(
      titre: titre,
      initial: {cle: valeur},
      champs: [
        Champ(
          cle,
          titre,
          type: TypeChamp.entier,
          obligatoire: true,
          min: min,
          max: max,
        ),
      ],
      envoyer: (c) async => c,
    ),
  );

  Widget _politiqueEdlEntree(
    ReglagesGestion s,
    ValueChanged<Map<String, dynamic>> maj,
  ) => Section(
    titre: "État des lieux d'entrée avant l'activation du bail",
    children: [
      RadioGroup<String>(
        groupValue: s.politiqueEdlEntree,
        onChanged: (v) => maj({'entry_inspection_policy': v}),
        child: Column(
          children: [
            for (final o in refs.options('politique_edl_entree'))
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(o.label),
                value: o.code,
              ),
          ],
        ),
      ),
    ],
  );

  /// Ordre d'essai des canaux (au moins un) et stratégie d'envoi.
  Widget _canaux(
    BuildContext context,
    ReglagesGestion s,
    ValueChanged<Map<String, dynamic>> maj,
  ) {
    final canaux = s.ordreCanaux;
    return Section(
      titre: 'Canaux de notification des locataires',
      children: [
        const Text(
          'Ordre d’essai des canaux (WhatsApp uniquement avec le consentement du locataire).',
        ),
        for (final c in const [
          OptionRef('push', 'Notification push'),
          OptionRef('whatsapp', 'WhatsApp'),
          OptionRef('sms', 'SMS'),
        ])
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(c.label),
            subtitle: canaux.contains(c.code)
                ? Text('Position ${canaux.indexOf(c.code) + 1}')
                : null,
            value: canaux.contains(c.code),
            onChanged: (v) {
              final n = [...canaux];
              v == true ? n.add(c.code) : n.remove(c.code);
              if (n.isEmpty) {
                return afficherErreur(context, 'Gardez au moins un canal');
              }
              maj({'channel_order': n});
            },
          ),
        const Divider(),
        RadioGroup<String>(
          groupValue: s.strategieNotification,
          onChanged: (v) => maj({'notification_strategy': v}),
          child: Column(
            children: [
              for (final o in refs.options('strategie_envoi'))
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o.label),
                  value: o.code,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
