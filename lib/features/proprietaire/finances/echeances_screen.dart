import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import 'encaissement.dart';

/// Échéances de loyer (§ 11) et impayés (§ 48 « Qui n'a pas payé ? »).
class EcheancesScreen extends StatefulWidget {
  const EcheancesScreen({super.key, this.impayes = false, this.bailId, this.locataireId, this.titre});
  final bool impayes;
  final String? bailId;
  final String? locataireId;
  final String? titre;

  @override
  State<EcheancesScreen> createState() => _EcheancesScreenState();
}

class _EcheancesScreenState extends State<EcheancesScreen> {
  final _liste = GlobalKey<ListePagineeState>();
  late String _filtre = widget.impayes ? 'impayes' : '';

  Future<void> _actions(Map<String, dynamic> e) async {
    final reste = entier(e['amount_due']) - entier(e['amount_paid']);
    final payable = !['paye', 'annule'].contains(e['status']);
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['label']}', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${nomComplet(e['tenant'] as Map?)} · Appartement ${(e['apartment'] as Map?)?['number'] ?? ''}'),
              const SizedBox(height: 8),
              Ligne('Montant dû', montant(e['amount_due'] as num?)),
              Ligne('Déjà payé', montant(e['amount_paid'] as num?)),
              Ligne('Reste', montant(reste)),
              Ligne('Échéance', date(e['due_date'] as String?)),
            ]),
          ),
          if (payable) ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Encaisser'), onTap: () => Navigator.pop(ctx, 'encaisser')),
          if (payable && entier(e['amount_paid']) == 0)
            ListTile(leading: const Icon(Icons.block), title: const Text("Annuler l'échéance"), onTap: () => Navigator.pop(ctx, 'annuler')),
        ]),
      ),
    );
    if (!mounted || choix == null) return;
    if (choix == 'encaisser') {
      if (await encaisser(context, echeance: e) != null) _liste.currentState?.recharger();
    } else {
      final motif = await confirmer(context,
          titre: "Annuler l'échéance", message: 'Elle ne sera plus due par le locataire.', action: 'Annuler', danger: true, motif: true);
      if (motif == null || !mounted) return;
      await executer(context, () => api.post<dynamic>('/echeances/${e['id']}/annuler', body: {'reason': motif}), succes: 'Échéance annulée');
      _liste.currentState?.recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('impayes', 'Impayés'),
      ('', 'Toutes'),
      for (final o in refs.options('statut_echeance')) (o.code, o.label),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? (widget.impayes ? 'Impayés' : 'Échéances'))),
      body: Column(children: [
        Filtres(options: options, valeur: _filtre, onChange: (v) => setState(() => _filtre = v)),
        Expanded(
          child: ListePaginee(
            key: _liste,
            cle: _filtre,
            vide: _filtre == 'impayes' ? 'Aucun impayé. Tous les loyers sont à jour.' : 'Aucune échéance',
            iconeVide: _filtre == 'impayes' ? Icons.verified_outlined : Icons.event_outlined,
            charger: (page) => api.get('/echeances', query: {
              'page': page,
              'lease_id': widget.bailId,
              'tenant_id': widget.locataireId,
              if (_filtre == 'impayes') 'impayes': true else 'status': _filtre,
              'tri': _filtre == 'impayes' ? 'due_date' : '-due_date',
            }),
            element: (context, e) {
              final reste = entier(e['amount_due']) - entier(e['amount_paid']);
              return ListTile(
                title: Text('${nomComplet(e['tenant'] as Map?)} · ${(e['apartment'] as Map?)?['number'] ?? ''}'),
                subtitle: Text('${e['label']} · échéance ${date(e['due_date'] as String?)}'),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Montant(reste > 0 && e['status'] != 'annule' ? reste : entier(e['amount_due']),
                      style: TextStyle(fontWeight: FontWeight.w600, color: e['status'] == 'en_retard' ? context.palette.danger : null)),
                  const SizedBox(height: AppTheme.espaceXs),
                  Statut(FamilleStatut.echeance, 'statut_echeance', e['status'] as String?),
                ]),
                onTap: () => _actions(e),
              );
            },
          ),
        ),
      ]),
    );
  }
}
