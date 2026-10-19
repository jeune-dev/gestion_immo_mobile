import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/sync/file_attente.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';

/// Bandeau des opérations créées hors ligne (cahier des charges § 35) :
/// « Synchronisation impossible [Réessayer] [Voir les opérations] ».
class BandeauSynchronisation extends StatelessWidget {
  const BandeauSynchronisation({super.key});

  @override
  Widget build(BuildContext context) {
    final file = Services.fileAttente;
    return ListenableBuilder(
      listenable: file,
      builder: (context, _) {
        if (file.operations.isEmpty) return const SizedBox.shrink();
        final n = file.operations.length;
        final c = couleursDuTon(context, file.echec ? TonStatut.danger : TonStatut.avertissement);
        return Material(
          color: c.fond,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(children: [
              Icon(file.echec ? Icons.sync_problem : Icons.cloud_upload_outlined, size: 18, color: c.texte),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.synchronisation
                      ? 'Synchronisation…'
                      : file.echec
                          ? 'Synchronisation impossible'
                          : '$n opération(s) en attente d’envoi',
                  style: TextStyle(color: c.texte, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(onPressed: file.synchronisation ? null : file.synchroniser, child: const Text('Réessayer')),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperationsScreen())),
                child: const Text('Voir'),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final file = Services.fileAttente;
    return Scaffold(
      appBar: AppBar(title: const Text('Opérations en attente')),
      body: ListenableBuilder(
        listenable: file,
        builder: (context, _) => file.operations.isEmpty
            ? const Vide('Toutes les opérations ont été envoyées.', icone: Icons.cloud_done_outlined)
            : ListView(
                padding: const EdgeInsets.all(AppTheme.espaceLg),
                children: [
                  const Encadre("Ces opérations ont été enregistrées sans réseau. Elles seront envoyées automatiquement au retour de la connexion."),
                  const SizedBox(height: AppTheme.espaceLg),
                  for (final OperationEnAttente op in file.operations)
                    Card(
                      child: ListTile(
                        title: Text(op.libelle),
                        subtitle: Text(op.erreur ?? 'Créée ${ilYa(op.creeLe.toUtc().toIso8601String())}'),
                        trailing: IconButton(
                          tooltip: 'Retirer',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => file.retirer(op),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppTheme.espaceLg),
                  FilledButton.icon(
                    onPressed: file.synchronisation ? null : file.synchroniser,
                    icon: const Icon(Icons.sync),
                    label: const Text('Synchroniser maintenant'),
                  ),
                ],
              ),
      ),
    );
  }
}
