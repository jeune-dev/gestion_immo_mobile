import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/navigation.dart';
import '../../commun/documents.dart';
import 'travaux_hub_screen.dart';

/// Fiche d'un artisan (§ 24).
class ArtisanDetail extends StatelessWidget {
  const ArtisanDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Artisan',
      charger: () => api.get<Map<String, dynamic>>('/artisans/$id'),
      builder: (context, data, recharger) {
        final a = Map<String, dynamic>.from(data['contractor'] as Map);
        final actif = a['is_active'] == true;
        return Scaffold(
          appBar: AppBar(
            title: Text('${a['name']}'),
            actions: [
              MenuActions(actions: [
                ('Modifier', () async {
                  if (await FormulairesTravaux.artisan(context, existant: a) != null) recharger();
                }, false),
                (actif ? 'Désactiver' : 'Réactiver', () async {
                  await executer(context, () => api.post<dynamic>('/artisans/$id/${actif ? 'desactiver' : 'reactiver'}'),
                      succes: actif ? 'Artisan désactivé' : 'Artisan réactivé');
                  recharger();
                }, false),
                ('Supprimer', () async {
                  final ok = await confirmer(context,
                      titre: "Supprimer l'artisan", message: 'Impossible tant qu’il a des travaux en cours.', action: 'Supprimer', danger: true);
                  if (ok == null || !context.mounted) return;
                  final fait = await executer(context, () => api.delete<dynamic>('/artisans/$id').then((_) => true), succes: 'Artisan supprimé');
                  if (fait == true && context.mounted) Navigator.pop(context);
                }, true),
              ]),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Ligne('Métier', refs.libelle('metier_artisan', a['trade'] as String?)),
              Ligne('Téléphone', a['phone'] as String?),
              Ligne('E-mail', a['email'] as String?),
              Ligne('Interventions', '${a['interventions_count'] ?? 0}'),
              Ligne('Total payé', montant(a['total_spent'] as num?)),
              Ligne('Statut', actif ? 'Actif' : 'Inactif'),
              if (a['notes'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${a['notes']}')),
              if (a['phone'] != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${a['phone']}')),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Appeler'),
                ),
              ],
            ]),
            const SizedBox(height: 16),
            SectionDocuments(type: 'contractor', id: id),
          ]),
        );
      },
    );
  }
}

/// Ouvre la fiche (utilisé par les listes).
Future<void> ouvrirArtisan(BuildContext context, String id) => ouvrir(context, ArtisanDetail(id: id));
