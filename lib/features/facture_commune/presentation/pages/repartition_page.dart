import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/bloc/repartition_bloc.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/bloc/repartition_event.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/bloc/repartition_state.dart';

/// Répartition (§ 17) : choix des appartements et, selon la méthode, consommation
/// ou montant de chacun ; aperçu calculé par l'API avant validation.
class RepartitionPage extends StatelessWidget {
  final FactureCommune facture;
  const RepartitionPage({super.key, required this.facture});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => di.sl<RepartitionBloc>()..add(LoadRepartition(facture)),
        child: _Repartition(facture: facture),
      );
}

class _Repartition extends StatefulWidget {
  final FactureCommune facture;
  const _Repartition({required this.facture});

  @override
  State<_Repartition> createState() => _RepartitionState();
}

class _RepartitionState extends State<_Repartition> {
  final Set<String> _choisis = {};
  final Map<String, TextEditingController> _valeurs = {};
  final _unite = TextEditingController(text: 'kWh');
  bool _initialise = false;

  String get _methode => widget.facture.methodeRepartition ?? '';

  Map<String, dynamic> _corps() {
    final ids = _choisis.toList();
    if (!widget.facture.parLigne) return {'apartment_ids': ids};
    return {
      'lines': [
        for (final id in ids)
          {
            'apartment_id': id,
            if (_methode == 'consommation')
              'consumption':
                  num.tryParse(_valeurs[id]!.text.replaceAll(',', '.')) ?? 0,
            if (_methode == 'personnalise')
              'amount': lireMontant(_valeurs[id]!.text) ?? 0,
          },
      ],
      // L'API refuse une unité vide ou de plus de 10 caractères
      if (_methode == 'consommation' && _unite.text.trim().isNotEmpty)
        'unit': _unite.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RepartitionBloc>();
    final factureId = widget.facture.id;
    return BlocConsumer<RepartitionBloc, RepartitionState>(
      listener: (context, state) {
        if (state is RepartitionLoaded && !_initialise) {
          _initialise = true;
          _choisis.addAll(
            state.appartements.where((a) => a.occupe).map((a) => a.id),
          );
          for (final a in state.appartements) {
            _valeurs[a.id] = TextEditingController();
          }
        } else if (state is RepartitionError) {
          afficherErreurApi(context, state.failure);
        } else if (state is RepartitionActionError) {
          afficherErreurApi(context, state.failure);
        } else if (state is RepartitionSuccess) {
          afficherSucces(context, state.message);
          Navigator.pop(context, true);
        }
      },
      // Les messages d'erreur ne redessinent pas l'écran.
      buildWhen: (_, state) =>
          state is RepartitionInitial ||
          state is RepartitionLoaded ||
          state is RepartitionError,
      builder: (context, state) {
        final apparts = state is RepartitionLoaded ? state.appartements : null;
        final a = state is RepartitionLoaded ? state.apercu : null;
        final enCours = state is RepartitionLoaded && state.enCours;
        return Scaffold(
          appBar: AppBar(title: const Text('Répartir la facture')),
          body: apparts == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Encadre(
                        '${refs.libelle('methode_repartition', _methode)} · total ${montant(widget.facture.montant)}'),
                    const SizedBox(height: AppTheme.espaceLg),
                    if (_methode == 'consommation')
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.espaceLg),
                        child: TextField(
                          controller: _unite,
                          maxLength: 10,
                          decoration: const InputDecoration(
                              labelText: 'Unité (kWh, m³…)'),
                        ),
                      ),
                    Card(
                      child: Column(
                        children: [
                          for (final ap in apparts)
                            CheckboxListTile(
                              value: _choisis.contains(ap.id),
                              onChanged: (v) => setState(() {
                                bloc.add(InvaliderApercuEvent());
                                v == true
                                    ? _choisis.add(ap.id)
                                    : _choisis.remove(ap.id);
                              }),
                              title: Text('Appartement ${ap.numero}'),
                              subtitle: widget.facture.parLigne &&
                                      _choisis.contains(ap.id)
                                  ? TextField(
                                      controller: _valeurs[ap.id],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: _methode == 'consommation'
                                            ? 'Consommation (${_unite.text})'
                                            : 'Montant (FCFA)',
                                      ),
                                      onChanged: (_) =>
                                          bloc.add(InvaliderApercuEvent()),
                                    )
                                  : Text(
                                      '${refs.libelle('statut_appartement', ap.statut)} · coefficient ${ap.coefficientCharges ?? 1}'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.espaceLg),
                    if (a == null)
                      FilledButton(
                        onPressed: enCours
                            ? null
                            : () => _choisis.isEmpty
                                ? afficherErreur(context,
                                    'Choisissez au moins un appartement')
                                : bloc.add(PrevisualiserRepartitionEvent(
                                    factureId, _corps())),
                        child: const Text('Prévisualiser'),
                      )
                    else ...[
                      Section(
                        titre: 'Aperçu',
                        padding: false,
                        children: [
                          for (final l in a.lignes)
                            ListTile(
                              title: Text(
                                  'Appartement ${l.logementNumero ?? ''}${l.locataire != null ? ' · ${nomDe(l.locataire)}' : ''}'),
                              subtitle: Text(l.explication ?? ''),
                              trailing: Montant(l.montant),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Ligne('Refacturé aux locataires',
                                    montant(a.totalRefacture)),
                                Ligne('À la charge du propriétaire',
                                    montant(a.partProprietaire)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.espaceLg),
                      FilledButton(
                        onPressed: enCours
                            ? null
                            : () => bloc
                                .add(RepartirFactureEvent(factureId, _corps())),
                        child: const Text('Valider la répartition'),
                      ),
                      TextButton(
                        onPressed: () => bloc.add(InvaliderApercuEvent()),
                        child: const Text('Modifier'),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
