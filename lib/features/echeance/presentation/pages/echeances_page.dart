import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/widgets/encaissement.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/annuler_echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/get_echeances.dart';

/// Échéances de loyer (§ 11) et impayés (§ 48 « Qui n'a pas payé ? »).
class EcheancesPage extends StatefulWidget {
  final bool impayes;
  final String? bailId;
  final String? locataireId;
  final String? titre;

  const EcheancesPage(
      {super.key,
      this.impayes = false,
      this.bailId,
      this.locataireId,
      this.titre});

  @override
  State<EcheancesPage> createState() => _EcheancesPageState();
}

class _EcheancesPageState extends State<EcheancesPage> {
  final _liste = GlobalKey<ListePagineeState<Echeance>>();
  late String _filtre = widget.impayes ? 'impayes' : '';

  Future<void> _actions(BuildContext context, Echeance e) async {
    final actions = context.read<ActionsCubit>();
    final payable = !['paye', 'annule'].contains(e.statut);
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.libelle ?? '',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                      '${nomDe(e.locataire)} · Appartement ${e.logementNumero ?? ''}'),
                  const SizedBox(height: 8),
                  Ligne('Montant dû', montant(e.montantDu)),
                  Ligne('Déjà payé', montant(e.montantPaye)),
                  Ligne('Reste', montant(e.reste)),
                  Ligne('Échéance', date(e.dateEcheance)),
                ],
              ),
            ),
            if (payable)
              ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Encaisser'),
                  onTap: () => Navigator.pop(ctx, 'encaisser')),
            if (payable && e.montantPaye == 0)
              ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Annuler l'échéance"),
                  onTap: () => Navigator.pop(ctx, 'annuler')),
          ],
        ),
      ),
    );
    if (!context.mounted || choix == null) return;
    if (choix == 'encaisser') {
      if (await encaisser(context, echeance: e)) {
        _liste.currentState?.recharger();
      }
    } else {
      final motif = await confirmer(
        context,
        titre: "Annuler l'échéance",
        message: 'Elle ne sera plus due par le locataire.',
        action: 'Annuler',
        danger: true,
        motif: true,
      );
      if (motif != null) {
        actions.executer(sl<AnnulerEcheance>()(e.id, motif),
            succes: 'Échéance annulée');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('impayes', 'Impayés'),
      ('', 'Toutes'),
      for (final o in refs.options('statut_echeance')) (o.code, o.label)
    ];
    return AvecActions(
      onReussite: () => _liste.currentState?.recharger(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(
                  widget.titre ?? (widget.impayes ? 'Impayés' : 'Échéances'))),
          body: Column(
            children: [
              Filtres(
                  options: options,
                  valeur: _filtre,
                  onChange: (v) => setState(() => _filtre = v)),
              Expanded(
                child: ListePaginee<Echeance>(
                  key: _liste,
                  cle: _filtre,
                  vide: _filtre == 'impayes'
                      ? 'Aucun impayé. Tous les loyers sont à jour.'
                      : 'Aucune échéance',
                  iconeVide: _filtre == 'impayes'
                      ? Icons.verified_outlined
                      : Icons.event_outlined,
                  charger: (page) => sl<GetEcheances>()(
                    page: page,
                    bailId: widget.bailId,
                    locataireId: widget.locataireId,
                    impayes: _filtre == 'impayes',
                    statut: _filtre == 'impayes' || _filtre.isEmpty
                        ? null
                        : _filtre,
                  ),
                  element: (context, e) => ListTile(
                    title: Text(
                        '${nomDe(e.locataire)} · ${e.logementNumero ?? ''}'),
                    subtitle: Text(
                        '${e.libelle ?? ''} · échéance ${date(e.dateEcheance)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Montant(
                          e.reste > 0 && e.statut != 'annule'
                              ? e.reste
                              : e.montantDu,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: e.statut == 'en_retard'
                                  ? context.palette.danger
                                  : null),
                        ),
                        const SizedBox(height: AppTheme.espaceXs),
                        Statut(FamilleStatut.echeance, 'statut_echeance',
                            e.statut),
                      ],
                    ),
                    onTap: () => _actions(context, e),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
