import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/errors/messages.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
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
    ..showSnackBar(
      SnackBar(
        backgroundColor: cs.error,
        content: Text(message, style: TextStyle(color: cs.onError)),
      ),
    );
}

/// Affiche le message de l'API tel quel (contrat § 0). Un 402 propose le
/// renouvellement : l'espace est en lecture seule tant que l'abonnement est échu.
/// Ouvre un lien (page de paiement, appel…) et prévient quand le téléphone
/// ne peut pas l'ouvrir, au lieu d'échouer en silence. Renvoie `true` si ouvert.
Future<bool> ouvrirLien(BuildContext context, String lien,
    {LaunchMode mode = LaunchMode.platformDefault}) async {
  final uri = Uri.tryParse(lien);
  var ouvert = false;
  try {
    ouvert = uri != null && await launchUrl(uri, mode: mode);
  } catch (_) {
    ouvert = false;
  }
  if (!ouvert && context.mounted) {
    afficherErreur(context, 'Impossible d’ouvrir ce lien sur ce téléphone.');
  }
  return ouvert;
}

/// Appel téléphonique (espaces retirés du numéro).
Future<bool> appeler(BuildContext context, String? telephone) =>
    ouvrirLien(context, 'tel:${(telephone ?? '').replaceAll(' ', '')}');

void afficherErreurApi(BuildContext context, Object e) {
  if (erreurAbonnement(e)) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abonnement à renouveler'),
        content: Text(
            '${messageErreur(e)}\n\nVos données restent consultables ; renouvelez pour les modifier.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Plus tard')),
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
  afficherErreur(context, messageErreur(e));
}

/// Exécute un cas d'usage : message de succès, ou message d'erreur. Renvoie
/// la valeur en cas de succès, `null` en cas d'échec.
Future<T?> executer<T>(
    BuildContext context, Future<Either<Failure, T>> Function() action,
    {String? succes}) async {
  final r = await action();
  if (!context.mounted) return r.fold((_) => null, (v) => v);
  return r.fold(
    (f) {
      afficherErreurApi(context, f);
      return null;
    },
    (v) {
      if (succes != null) afficherSucces(context, succes);
      return v;
    },
  );
}

/// Comme [executer], pour une action sans valeur de retour : vrai si elle a réussi.
Future<bool> reussir(
    BuildContext context, Future<Either<Failure, dynamic>> Function() action,
    {String? succes}) async {
  final r = await action();
  if (!context.mounted) return r.isRight();
  return r.fold(
    (f) {
      afficherErreurApi(context, f);
      return false;
    },
    (_) {
      if (succes != null) afficherSucces(context, succes);
      return true;
    },
  );
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
  return showDialog<String>(
    context: context,
    builder: (_) => _Confirmation(
      titre: titre,
      message: message,
      action: action,
      danger: danger,
      motif: motif,
      motifObligatoire: motifObligatoire,
      libelleMotif: libelleMotif,
      minMotif: minMotif,
      masque: masque,
    ),
  );
}

/// Boîte de [confirmer] : elle possède le champ du motif et le libère.
class _Confirmation extends StatefulWidget {
  final String titre;
  final String message;
  final String action;
  final bool danger;
  final bool motif;
  final bool motifObligatoire;
  final String libelleMotif;
  final int minMotif;
  final bool masque;

  const _Confirmation({
    required this.titre,
    required this.message,
    required this.action,
    required this.danger,
    required this.motif,
    required this.motifObligatoire,
    required this.libelleMotif,
    required this.minMotif,
    required this.masque,
  });

  @override
  State<_Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<_Confirmation> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final w = widget;
    final invalide =
        w.motif && w.motifObligatoire && ctrl.text.trim().length < w.minMotif;
    final cs = Theme.of(ctx).colorScheme;
    return AlertDialog(
      title: Text(w.titre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (w.message.isNotEmpty) Text(w.message),
          if (w.motif) ...[
            const SizedBox(height: AppTheme.espaceLg),
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: w.masque,
              minLines: w.masque ? 1 : 2,
              maxLines: w.masque ? 1 : 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: '${w.libelleMotif}${w.motifObligatoire ? ' *' : ''}',
                helperText: w.motifObligatoire
                    ? '${w.minMotif} caractères minimum'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler')),
        FilledButton(
          style: w.danger
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error, foregroundColor: cs.onError)
              : null,
          onPressed:
              invalide ? null : () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(w.action),
        ),
      ],
    );
  }
}

/// Télécharge un PDF de l'API (avec le jeton) puis l'ouvre avec le lecteur du
/// téléphone ; [partager] ouvre la feuille de partage (WhatsApp, e-mail…).
Future<void> ouvrirPdf(
  BuildContext context,
  Future<Either<Failure, Uint8List>> Function() telecharger,
  String nomFichier, {
  bool partager = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(
      content: Text('Préparation du document…'),
      duration: Duration(seconds: 20)));
  try {
    final octets = (await telecharger()).fold((f) => throw f, (o) => o);
    final dossier = await getTemporaryDirectory();
    final fichier = File('${dossier.path}/$nomFichier');
    await fichier.writeAsBytes(octets, flush: true);
    messenger.hideCurrentSnackBar();
    if (partager) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(fichier.path, mimeType: 'application/pdf')],
          subject: nomFichier,
        ),
      );
    } else {
      final r = await OpenFilex.open(fichier.path, type: 'application/pdf');
      if (r.type != ResultType.done && context.mounted) {
        await SharePlus.instance.share(ShareParams(
            files: [XFile(fichier.path, mimeType: 'application/pdf')]));
      }
    }
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) afficherErreurApi(context, e);
  }
}

// ── Sélection d'une entité de l'API ──────────────────────────────────────────

class EntiteChoisie<T> {
  final String id;
  final String libelle;
  final T valeur;
  const EntiteChoisie(this.id, this.libelle, this.valeur);
}

/// Liste paginée dans laquelle on choisit (immeuble, appartement, locataire,
/// bail…) : chaque fonctionnalité fournit la sienne, branchée sur son cas d'usage.
class SourceEntite<T> {
  /// Page `page`, filtrée par la recherche `q` (vide = pas de filtre).
  final Future<Either<Failure, PageResultat<T>>> Function(int page, String q)
      charger;
  final String Function(T) id;
  final String Function(T) libelle;
  final String Function(T)? sousTitre;
  final bool recherche;

  const SourceEntite(
      {required this.charger,
      required this.id,
      required this.libelle,
      this.sousTitre,
      this.recherche = true});
}

Future<EntiteChoisie<dynamic>?> choisirEntite(
    BuildContext context, SourceEntite<dynamic> source,
    {required String titre}) {
  return showModalBottomSheet<EntiteChoisie<dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _Selecteur(source: source, titre: titre),
  );
}

class _Selecteur extends StatefulWidget {
  final SourceEntite<dynamic> source;
  final String titre;
  const _Selecteur({required this.source, required this.titre});

  @override
  State<_Selecteur> createState() => _SelecteurState();
}

class _SelecteurState extends State<_Selecteur> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text(widget.titre,
                        style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
          ),
          if (source.recherche)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search), hintText: 'Rechercher'),
                onSubmitted: (v) => setState(() => _q = v.trim()),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListePaginee<dynamic>(
              cle: _q,
              charger: (page) => source.charger(page, _q),
              element: (context, e) => ListTile(
                title: Text(source.libelle(e)),
                subtitle: source.sousTitre == null
                    ? null
                    : Text(source.sousTitre!(e)),
                onTap: () => Navigator.pop(context,
                    EntiteChoisie<dynamic>(source.id(e), source.libelle(e), e)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
