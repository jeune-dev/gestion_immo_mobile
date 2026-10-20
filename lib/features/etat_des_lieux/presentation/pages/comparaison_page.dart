import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/bloc/comparaison_bloc.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/bloc/comparaison_event.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/bloc/comparaison_state.dart';

/// Comparaison entrée / sortie (§ 52.3) : éléments dégradés, absents, nouveaux.
class ComparaisonPage extends StatelessWidget {
  final String bailId;
  const ComparaisonPage({super.key, required this.bailId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ComparaisonBloc>()..add(LoadComparaison(bailId)),
      child: BlocConsumer<ComparaisonBloc, ComparaisonState>(
        listener: (context, state) {
          if (state is ComparaisonActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is ComparaisonInitial ||
            state is ComparaisonLoading ||
            state is ComparaisonLoaded ||
            state is ComparaisonError,
        builder: (context, state) {
          if (state is ComparaisonLoaded) {
            return _buildFiche(context, state.comparaison);
          }
          return VueChargement(
            titre: 'Comparaison',
            failure: state is ComparaisonError ? state.failure : null,
            onReessayer: () =>
                context.read<ComparaisonBloc>().add(LoadComparaison(bailId)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, ComparaisonEdl c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrée / sortie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            children: [
              Ligne('Éléments comparés', '${c.elementsSortie}'),
              Ligne('Identiques', '${c.identiques}'),
              Ligne('Dégradés', '${c.degrades}'),
              Ligne('Améliorés', '${c.ameliores}'),
              Ligne('Absents à la sortie', '${c.absents}'),
            ],
          ),
          const SizedBox(height: 16),
          if (c.ecarts.isEmpty)
            const Vide('Aucune dégradation constatée',
                icone: Icons.verified_outlined),
          for (final e in c.ecarts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.piece ?? ''} · ${e.element ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        'Entrée : ${e.etatEntree ?? '—'}  →  Sortie : ${e.etatSortie ?? '—'}'),
                    if (e.commentaireSortie != null)
                      Text('« ${e.commentaireSortie} »'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
