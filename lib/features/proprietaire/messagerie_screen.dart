import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../commun/documents.dart';

/// Fils de discussion du propriétaire avec ses locataires (§ 54.1).
class MessagerieScreen extends StatefulWidget {
  const MessagerieScreen({super.key});

  @override
  State<MessagerieScreen> createState() => _MessagerieScreenState();
}

class _MessagerieScreenState extends State<MessagerieScreen> {
  final _liste = GlobalKey<ListePagineeState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie')),
      body: ListePaginee(
        key: _liste,
        vide: 'Aucune conversation. Écrivez à un locataire depuis sa fiche.',
        iconeVide: Icons.chat_bubble_outline,
        charger: (page) => api.get('/messagerie/fils', query: {'page': page}),
        element: (context, f) {
          final t = f['tenant'] as Map? ?? {};
          final dernier = f['last_message'] as Map?;
          final nonLus = entier(f['unread_count']);
          return ListTile(
            leading: CircleAvatar(child: Text(initiales(t))),
            title: Text(nomComplet(t), style: TextStyle(fontWeight: nonLus > 0 ? FontWeight.w600 : FontWeight.w400)),
            subtitle: Text(dernier == null ? 'Aucun message' : '${dernier['body'] ?? 'Photo'}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: nonLus > 0 ? Badge(label: Text('$nonLus')) : Text(ilYa(f['last_message_at'] as String?), style: const TextStyle(fontSize: 12)),
            onTap: () async {
              await ouvrir(context, ConversationScreen.proprietaire(locataireId: '${t['id']}', titre: nomComplet(t), filId: '${f['id']}'));
              _liste.currentState?.recharger();
            },
          );
        },
      ),
    );
  }
}

/// Conversation (propriétaire ou locataire) : messages texte et photos.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen._({required this.titre, this.filId, this.locataireId, required this.locataire});

  factory ConversationScreen.proprietaire({required String locataireId, required String titre, String? filId}) =>
      ConversationScreen._(titre: titre, locataireId: locataireId, filId: filId, locataire: false);

  factory ConversationScreen.locataire({required String filId, required String titre}) =>
      ConversationScreen._(titre: titre, filId: filId, locataire: true);

  final String titre;
  final String? filId;
  final String? locataireId;
  final bool locataire;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _texte = TextEditingController();
  late String? _fil = widget.filId;
  List<Map> _messages = [];
  bool _charge = true;
  bool _envoi = false;
  Object? _erreur;

  String get _base => widget.locataire ? '/locataire/messagerie/$_fil' : '/messagerie/fils/$_fil';
  String get _envoiBase => widget.locataire ? '/locataire/messagerie/$_fil' : '/messagerie/locataires/${widget.locataireId}';
  String get _moi => widget.locataire ? 'locataire' : 'proprietaire';

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    // Ouvert depuis la fiche locataire : retrouver le fil existant, s'il y en a un
    if (_fil == null && widget.locataireId != null) {
      try {
        final r = await api.get<Map<String, dynamic>>('/messagerie/fils', query: {'limit': 100});
        for (final f in (r['items'] as List).cast<Map>()) {
          if ((f['tenant'] as Map?)?['id'] == widget.locataireId) _fil = '${f['id']}';
        }
      } catch (_) {}
    }
    await _charger();
  }

  Future<void> _charger() async {
    if (_fil == null) return setState(() => _charge = false);
    try {
      final r = await api.get<Map<String, dynamic>>('$_base/messages', query: {'limit': 100});
      final items = (r['items'] as List).cast<Map>().toList()
        ..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));
      setState(() {
        _messages = items;
        _charge = false;
        _erreur = null;
      });
      api.post<dynamic>('$_base/lu').ignore();
    } catch (e) {
      setState(() {
        _erreur = e;
        _charge = false;
      });
    }
  }

  Future<void> _envoyer() async {
    final texte = _texte.text.trim();
    if (texte.isEmpty) return;
    setState(() => _envoi = true);
    final r = await executer(context, () => api.post<Map<String, dynamic>>('$_envoiBase/messages', body: {'body': texte}, idempotence: nouvelleCle()));
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r != null) {
      _texte.clear();
      _fil ??= '${(r['message'] as Map)['thread_id']}';
      await _charger();
    }
  }

  Future<void> _photo() async {
    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;
    setState(() => _envoi = true);
    final r = await executer(context, () => api.upload<Map<String, dynamic>>('$_envoiBase/photos', cheminFichier: photo.path, idempotence: nouvelleCle()));
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r != null) {
      _fil ??= '${(r['message'] as Map)['thread_id']}';
      await _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: Column(children: [
        Expanded(
          child: _charge
              ? const Center(child: CircularProgressIndicator())
              : _erreur != null
                  ? VueErreur(_erreur!, onReessayer: _charger)
                  : _messages.isEmpty
                      ? const Vide('Aucun message. Écrivez le premier.', icone: Icons.chat_bubble_outline)
                      : RefreshIndicator(
                          onRefresh: _charger,
                          child: ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[_messages.length - 1 - i];
                              final moi = m['sender_role'] == _moi;
                              final doc = m['document'] as Map?;
                              return Align(
                                alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: moi ? cs.primary : context.palette.surfaceAlt,
                                    borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    if (doc != null)
                                      InkWell(
                                        onTap: () => ouvrirDocument(context, doc),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(AppTheme.rayon),
                                          child: SizedBox(width: 200, height: 150, child: ImageApi('${doc['id']}')),
                                        ),
                                      ),
                                    if ((m['body'] as String?)?.isNotEmpty == true)
                                      Text('${m['body']}', style: TextStyle(color: moi ? cs.onPrimary : cs.onSurface)),
                                    const SizedBox(height: 2),
                                    Text(dateHeure(m['created_at'] as String?),
                                        style: TextStyle(fontSize: 11, color: (moi ? cs.onPrimary : cs.onSurface).withValues(alpha: 0.7))),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(children: [
              IconButton(tooltip: 'Envoyer une photo', onPressed: _envoi ? null : _photo, icon: const Icon(Icons.photo_camera_outlined)),
              Expanded(
                child: TextField(
                  controller: _texte,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Votre message', isDense: true),
                ),
              ),
              IconButton(tooltip: 'Envoyer', onPressed: _envoi ? null : _envoyer, icon: Icon(Icons.send, color: cs.primary)),
            ]),
          ),
        ),
      ]),
    );
  }
}
