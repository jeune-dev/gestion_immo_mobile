import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/app_theme.dart';
import '../../commun/documents.dart';
import 'biens_screen.dart';
import 'formulaires.dart';

class ImmeubleDetail extends StatefulWidget {
  const ImmeubleDetail({super.key, required this.id});
  final String id;

  @override
  State<ImmeubleDetail> createState() => _ImmeubleDetailState();
}

class _ImmeubleDetailState extends State<ImmeubleDetail> {
  final _cle = GlobalKey<ChargeurState<List<dynamic>>>();

  Future<List<dynamic>> _charger() => Future.wait([
        api.get<Map<String, dynamic>>('/immeubles/${widget.id}'),
        api.get<Map<String, dynamic>>('/appartements', query: {'building_id': widget.id, 'limit': 100, 'tri': 'number'}),
      ]);

  @override
  Widget build(BuildContext context) {
    return Chargeur<List<dynamic>>(
      key: _cle,
      page: true,
      titre: 'Immeuble',
      charger: _charger,
      builder: (context, data, recharger) {
        final b = Map<String, dynamic>.from((data[0] as Map)['building'] as Map);
        final apps = ((data[1] as Map)['items'] as List).cast<Map<String, dynamic>>();
        return Scaffold(
          appBar: AppBar(
            title: Text('${b['name']}'),
            actions: [
              MenuActions(actions: [
                ('Modifier', () async {
                  if (await FormulairesBiens.immeuble(context, existant: b) != null) recharger();
                }, false),
                ('Supprimer', () async {
                  final ok = await confirmer(context,
                      titre: 'Supprimer l’immeuble', message: 'Seul un immeuble sans appartement peut être supprimé.', action: 'Supprimer', danger: true);
                  if (ok == null || !context.mounted) return;
                  final r = await executer(context, () => api.delete<dynamic>('/immeubles/${b['id']}').then((_) => true), succes: 'Immeuble supprimé');
                  if (r == true && context.mounted) Navigator.pop(context);
                }, true),
              ]),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              if (await FormulairesBiens.appartement(context, immeuble: b) != null) recharger();
            },
            icon: const Icon(Icons.add),
            label: const Text('Appartement'),
          ),
          body: RefreshIndicator(
            onRefresh: recharger,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
              Section(children: [
                Ligne('Adresse', [b['address'], b['district'], b['city']].whereType<String>().join(', ')),
                Ligne("Nombre d'étages", b['floors_count'] == null ? null : '${b['floors_count']}'),
                Ligne('Appartements', '${apps.length}${b['declared_apartments_count'] != null ? ' / ${b['declared_apartments_count']} prévus' : ''}'),
                Ligne('Occupés', '${apps.where((a) => a['status'] == 'occupe').length}'),
                Ligne('Loyers mensuels', montant(apps.fold<int>(0, (t, a) => t + entier(a['rent_amount'])))),
                if (b['description'] != null) ...[const SizedBox(height: AppTheme.espaceSm), Text('${b['description']}')],
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: 'Appartements',
                padding: false,
                children: apps.isEmpty
                    ? [const Vide('Aucun appartement dans cet immeuble')]
                    : [for (final a in apps) TuileAppartement(a: a, onRetour: recharger)],
              ),
              const SizedBox(height: AppTheme.espaceLg),
              SectionDocuments(type: 'building', id: widget.id),
            ]),
          ),
        );
      },
    );
  }
}
