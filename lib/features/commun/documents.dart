import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Choisit une photo. La permission n'est demandée qu'à ce moment (§ 33, CNIL) ;
/// l'image est compressée côté téléphone avant l'envoi (§ 37).
Future<XFile?> choisirPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Prendre une photo'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choisir dans la galerie'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ]),
    ),
  );
  if (source == null) return null;
  return ImagePicker().pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 80);
}

/// Image servie par l'API (miniature d'abord, § 37) : chargée avec le jeton.
class ImageApi extends StatelessWidget {
  const ImageApi(this.documentId, {super.key, this.taille = 'miniature', this.fit = BoxFit.cover});
  final String documentId;
  final String taille;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: api.telecharger('/documents/$documentId/fichier', query: {'taille': taille}),
      builder: (context, s) {
        if (s.hasData) return Image.memory(s.data!, fit: fit, gaplessPlayback: true);
        return Container(
          color: context.palette.surfaceAlt,
          child: Center(child: s.hasError ? const Icon(Icons.broken_image_outlined) : const CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}

void afficherImage(BuildContext context, String documentId) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(),
      body: InteractiveViewer(child: Center(child: ImageApi(documentId, taille: 'originale', fit: BoxFit.contain))),
    ),
  ));
}

/// Ouvre un document stocké : image en plein écran, PDF dans le lecteur.
void ouvrirDocument(BuildContext context, Map doc) {
  final mime = '${doc['mime_type'] ?? ''}';
  if (mime.startsWith('image/')) return afficherImage(context, '${doc['id']}');
  ouvrirPdf(context, '/documents/${doc['id']}/fichier', '${doc['original_name'] ?? 'document.pdf'}');
}

/// Documents et photos rattachés à une entité (immeuble, appartement, locataire, bail, artisan).
class SectionDocuments extends StatefulWidget {
  const SectionDocuments({super.key, required this.type, required this.id, this.titre = 'Documents et photos', this.ajout = true});
  final String type;
  final String id;
  final String titre;

  /// L'ajout direct (`POST /documents`) n'existe que pour immeuble, appartement,
  /// locataire, bail et artisan ; les autres entités ont leur propre route.
  final bool ajout;

  @override
  State<SectionDocuments> createState() => _SectionDocumentsState();
}

class _SectionDocumentsState extends State<SectionDocuments> {
  late Future<Map<String, dynamic>> _docs = _charger();

  Future<Map<String, dynamic>> _charger() =>
      api.get<Map<String, dynamic>>('/documents', query: {'entity_type': widget.type, 'entity_id': widget.id, 'limit': 50});

  Future<void> _ajouter() async {
    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;
    final ok = await executer(
      context,
      () => api.upload<dynamic>('/documents',
          cheminFichier: photo.path,
          champs: {'entity_type': widget.type, 'entity_id': widget.id, 'category': 'photo', 'captured_at': DateTime.now().toUtc().toIso8601String()},
          idempotence: nouvelleCle()),
      succes: 'Photo ajoutée',
    );
    if (ok != null) setState(() => _docs = _charger());
  }

  void _recharger() => setState(() => _docs = _charger());

  /// Catégories que l'API laisse supprimer (les pièces probantes — contrat,
  /// quittance, état des lieux, reçu — restent : 409 DOCUMENT_PROTEGE).
  static const _supprimables = ['photo', 'piece_identite', 'autre', 'justificatif', 'facture'];

  /// Seuls les documents d'un locataire ou d'un bail concernent un locataire
  /// et peuvent lui être partagés.
  bool get _partageable => widget.type == 'tenant' || widget.type == 'lease';

  Future<void> _partagerLien(Map d) async {
    final r = await executer(context, () => api.get<Map<String, dynamic>>('/documents/${d['id']}/lien', cache: false));
    if (r == null || !mounted) return;
    final url = '${r['url'] ?? ''}';
    if (!url.startsWith('http')) {
      return afficherErreur(context, 'Lien temporaire indisponible pour ce document : ouvrez-le puis partagez le fichier.');
    }
    final minutes = r['expires_in'] is num ? ((r['expires_in'] as num) / 60).round() : null;
    await SharePlus.instance.share(ShareParams(
      text: url,
      subject: '${d['original_name'] ?? 'Document'}${minutes != null ? ' (lien valable $minutes min)' : ''}',
    ));
  }

  Future<void> _visibilite(Map d, bool visible) async {
    final r = await executer(context, () => api.patch<dynamic>('/documents/${d['id']}', body: {'visible_to_tenant': visible}),
        succes: visible ? 'Document partagé avec le locataire' : 'Document retiré du partage');
    if (r != null) _recharger();
  }

  Future<void> _supprimer(Map d) async {
    final ok = await confirmer(context,
        titre: 'Supprimer le document', message: 'Le document sera définitivement retiré.', action: 'Supprimer', danger: true);
    if (ok == null || !mounted) return;
    final r = await executer(context, () => api.delete<dynamic>('/documents/${d['id']}').then((_) => true), succes: 'Document supprimé');
    if (r == true) _recharger();
  }

  Future<void> _actions(Map d) async {
    final visible = d['visible_to_tenant'] == true;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Ouvrir'),
            onTap: () {
              Navigator.pop(ctx);
              ouvrirDocument(context, d);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Partager un lien temporaire'),
            onTap: () {
              Navigator.pop(ctx);
              _partagerLien(d);
            },
          ),
          if (widget.ajout && _partageable)
            SwitchListTile(
              secondary: const Icon(Icons.visibility_outlined),
              title: const Text('Visible par le locataire'),
              value: visible,
              onChanged: (v) {
                Navigator.pop(ctx);
                _visibilite(d, v);
              },
            ),
          if (widget.ajout && _supprimables.contains(d['category']))
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('Supprimer', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _supprimer(d);
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      titre: widget.titre,
      action: widget.ajout ? IconButton(tooltip: 'Ajouter une photo', onPressed: _ajouter, icon: const Icon(Icons.add_a_photo_outlined)) : null,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _docs,
          builder: (context, s) {
            if (!s.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            final docs = (s.data!['items'] as List).cast<Map>();
            if (docs.isEmpty) return Text('Aucun document', style: TextStyle(color: context.palette.texteSecondaire));
            final grille = Wrap(spacing: AppTheme.espaceSm, runSpacing: AppTheme.espaceSm, children: [
              for (final d in docs)
                InkWell(
                  onTap: () => ouvrirDocument(context, d),
                  onLongPress: () => _actions(d),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.rayon),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: '${d['mime_type']}'.startsWith('image/') && d['has_thumbnail'] == true
                          ? ImageApi('${d['id']}')
                          : Container(
                              color: context.palette.surfaceAlt,
                              padding: const EdgeInsets.all(6),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.description_outlined),
                                Text(refs.libelle('categorie_document', d['category'] as String?),
                                    maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                                Text(date(d['created_at'] as String?), style: const TextStyle(fontSize: 10)),
                              ]),
                            ),
                    ),
                  ),
                ),
            ]);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              grille,
              const SizedBox(height: AppTheme.espaceSm),
              Text('Appui long sur un document : partager, gérer, supprimer.',
                  style: TextStyle(fontSize: 12, color: context.palette.texteSecondaire)),
            ]);
          },
        ),
      ],
    );
  }
}
