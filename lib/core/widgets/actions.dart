import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_theme.dart';
import '../api/api_exception.dart';
import '../services.dart';
import 'chargement.dart';

void afficherSucces(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void afficherErreur(BuildContext context, String message) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: cs.error,
      content: Text(message, style: TextStyle(color: cs.onError)),
    ));
}

/// Affiche le message de l'API tel quel (contrat § 0). Un 402 propose le
/// renouvellement : l'espace est en lecture seule tant que l'abonnement est échu.
void afficherErreurApi(BuildContext context, Object e) {
  if (e is ApiException && e.abonnementRequis) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abonnement à renouveler'),
        content: Text('${e.message}\n\nVos données restent consultables ; renouvelez pour les modifier.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              GoRouter.of(context).push('/p/abonnement');
            },
            child: const Text('Renouveler'),
          ),
        ],
      ),
    );
    return;
  }
  afficherErreur(context, e is ApiException ? e.messageComplet : 'Une erreur est survenue.');
}

/// Exécute une action de l'API : message de succès, ou message d'erreur.
Future<T?> executer<T>(BuildContext context, Future<T> Function() action, {String? succes}) async {
  try {
    final r = await action();
    if (context.mounted && succes != null) afficherSucces(context, succes);
    return r;
  } catch (e) {
    if (context.mounted) afficherErreurApi(context, e);
    return null;
  }
}

/// Confirmation d'une action. Avec [motif] : renvoie le texte saisi (null = annulé).
/// Sans motif : renvoie '' si confirmé, null sinon.
Future<String?> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String action = 'Confirmer',
  bool danger = false,
  bool motif = false,
  bool motifObligatoire = true,
  String libelleMotif = 'Motif',
  int minMotif = 3,
  bool masque = false,
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final invalide = motif && motifObligatoire && ctrl.text.trim().length < minMotif;
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(titre),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (message.isNotEmpty) Text(message),
            if (motif) ...[
              const SizedBox(height: AppTheme.espaceLg),
              TextField(
                controller: ctrl,
                autofocus: true,
                obscureText: masque,
                minLines: masque ? 1 : 2,
                maxLines: masque ? 1 : 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: '$libelleMotif${motifObligatoire ? ' *' : ''}',
                  helperText: motifObligatoire ? '$minMotif caractères minimum' : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: danger ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
              onPressed: invalide ? null : () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(action),
            ),
          ],
        );
      },
    ),
  );
}

/// Télécharge un PDF de l'API (avec le jeton) puis l'ouvre avec le lecteur du
/// téléphone ; [partager] ouvre la feuille de partage (WhatsApp, e-mail…).
Future<void> ouvrirPdf(BuildContext context, String chemin, String nomFichier, {bool partager = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Préparation du document…'), duration: Duration(seconds: 20)));
  try {
    final octets = await api.telecharger(chemin);
    final dossier = await getTemporaryDirectory();
    final fichier = File('${dossier.path}/$nomFichier');
    await fichier.writeAsBytes(octets, flush: true);
    messenger.hideCurrentSnackBar();
    if (partager) {
      await SharePlus.instance.share(ShareParams(files: [XFile(fichier.path, mimeType: 'application/pdf')], subject: nomFichier));
    } else {
      final r = await OpenFilex.open(fichier.path, type: 'application/pdf');
      if (r.type != ResultType.done && context.mounted) {
        await SharePlus.instance.share(ShareParams(files: [XFile(fichier.path, mimeType: 'application/pdf')]));
      }
    }
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) afficherErreurApi(context, e);
  }
}

// ── Sélection d'une entité de l'API ──────────────────────────────────────────

class EntiteChoisie {
  const EntiteChoisie(this.id, this.libelle, this.donnees);
  final String id;
  final String libelle;
  final Map<String, dynamic> donnees;
}

/// Liste de l'API dans laquelle on choisit (immeuble, appartement, locataire, bail…).
class SourceEntite {
  const SourceEntite(this.chemin, {required this.libelle, this.sousTitre, this.query = const {}, this.recherche = true});
  final String chemin;
  final Map<String, dynamic> query;
  final String Function(Map<String, dynamic>) libelle;
  final String Function(Map<String, dynamic>)? sousTitre;
  final bool recherche;
}

Future<EntiteChoisie?> choisirEntite(BuildContext context, SourceEntite source, {required String titre}) {
  return showModalBottomSheet<EntiteChoisie>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _Selecteur(source: source, titre: titre),
  );
}

class _Selecteur extends StatefulWidget {
  const _Selecteur({required this.source, required this.titre});
  final SourceEntite source;
  final String titre;

  @override
  State<_Selecteur> createState() => _SelecteurState();
}

class _SelecteurState extends State<_Selecteur> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(children: [
            Expanded(child: Text(widget.titre, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
        ),
        if (widget.source.recherche)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher'),
              onSubmitted: (v) => setState(() => _q = v.trim()),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListePaginee(
            cle: _q,
            charger: (page) => api.get<Map<String, dynamic>>(widget.source.chemin,
                query: {...widget.source.query, 'page': page, 'limit': 30, if (_q.isNotEmpty) 'q': _q}),
            element: (context, e) => ListTile(
              title: Text(widget.source.libelle(e)),
              subtitle: widget.source.sousTitre == null ? null : Text(widget.source.sousTitre!(e)),
              onTap: () => Navigator.pop(context, EntiteChoisie('${e['id']}', widget.source.libelle(e), e)),
            ),
          ),
        ),
      ]),
    );
  }
}
