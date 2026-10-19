import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/referentiels.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../core/widgets/sources.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';

/// États des lieux avec photos (§ 52).
class EtatsDesLieux {
  /// Crée un état des lieux (brouillon, pièces types pré-remplies) puis l'ouvre.
  static Future<Map?> creer(BuildContext context, {String? bailId, String? type}) async {
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Nouvel état des lieux',
        initial: {'type': ?type, 'performed_at': aujourdhui()},
        intro: const Text('Les pièces usuelles sont proposées automatiquement selon le type de logement ; vous pourrez en ajouter.'),
        champs: [
          if (bailId == null) Champ('lease_id', 'Bail', type: TypeChamp.entite, obligatoire: true, entite: Sources.baux(statut: '')),
          const Champ('type', 'Type', type: TypeChamp.selection, referentiel: 'type_etat_des_lieux', obligatoire: true),
          const Champ('performed_at', 'Date de la visite', type: TypeChamp.date),
        ],
        libelleEnvoi: 'Créer',
        envoyer: (c) async {
          final corps = {...c, 'lease_id': ?bailId, 'client_reference': 'edl-$cle'};
          return (await api.post<Map<String, dynamic>>('/etats-des-lieux', body: corps, idempotence: cle))['inspection'];
        },
      ),
    );
    if (r != null && context.mounted) await ouvrir(context, EtatDesLieuxDetail(id: '${r['id']}'));
    return r;
  }
}

class ListeEtatsDesLieux extends StatelessWidget {
  const ListeEtatsDesLieux({super.key, required this.cle});
  final GlobalKey<ListePagineeState> cle;

  @override
  Widget build(BuildContext context) {
    return ListePaginee(
      key: cle,
      vide: 'Aucun état des lieux',
      iconeVide: Icons.fact_check_outlined,
      charger: (page) => api.get('/etats-des-lieux', query: {'page': page, 'tri': '-created_at'}),
      element: (context, e) => ListTile(
        title: Text('${refs.libelle('type_etat_des_lieux', e['type'] as String?)} · ${nomComplet(e['tenant'] as Map?)}'),
        subtitle: Text('Appartement ${(e['apartment'] as Map?)?['number'] ?? ''} · v${e['version']} · ${date((e['performed_at'] ?? e['created_at']) as String?)}'),
        trailing: Statut(FamilleStatut.etatDesLieux, 'statut_etat_des_lieux', e['status'] as String?),
        onTap: () async {
          await ouvrir(context, EtatDesLieuxDetail(id: '${e['id']}'));
          cle.currentState?.recharger();
        },
      ),
    );
  }
}

class EtatDesLieuxDetail extends StatefulWidget {
  const EtatDesLieuxDetail({super.key, required this.id});
  final String id;

  @override
  State<EtatDesLieuxDetail> createState() => _EtatDesLieuxDetailState();
}

class _EtatDesLieuxDetailState extends State<EtatDesLieuxDetail> {
  Map<String, dynamic>? _edl;
  Object? _erreur;

  /// Saisies non encore envoyées : item_id → (état, commentaire).
  final Map<String, (String, String?)> _saisies = {};
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/etats-des-lieux/${widget.id}');
      setState(() {
        _edl = Map<String, dynamic>.from(r['inspection'] as Map);
        _erreur = null;
      });
    } catch (e) {
      setState(() => _erreur = e);
    }
  }

  bool get _modifiable => _edl?['status'] == 'brouillon';

  /// Enregistre toutes les saisies en une requête (§ 52.4, saisie synchronisée).
  Future<bool> _enregistrer() async {
    if (_saisies.isEmpty) return true;
    setState(() => _envoi = true);
    final ok = await executer(
      context,
      () => api.put<dynamic>('/etats-des-lieux/${widget.id}/saisie', body: {
        'items': [
          for (final e in _saisies.entries) {'item_id': e.key, 'condition': e.value.$1, 'comment': e.value.$2},
        ],
      }),
      succes: 'Saisie enregistrée',
    );
    if (!mounted) return false;
    setState(() => _envoi = false);
    if (ok == null) return false;
    _saisies.clear();
    await _charger();
    return true;
  }

  Future<void> _general() async {
    final e = _edl!;
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Relevés et observations',
        initial: e,
        champs: const [
          Champ('water_meter', 'Compteur d’eau (m³)', type: TypeChamp.decimal, nullable: true),
          Champ('electricity_meter', 'Compteur d’électricité (kWh)', type: TypeChamp.decimal, nullable: true),
          Champ('keys_count', 'Nombre de clés remises', type: TypeChamp.entier, min: 0, max: 100, nullable: true),
          Champ('keys_details', 'Détail des clés', maxLongueur: 2000),
          Champ('general_observations', 'Observations générales', type: TypeChamp.multiligne, maxLongueur: 5000),
        ],
        messageSucces: 'Enregistré',
        envoyer: (c) => api.patch<Map<String, dynamic>>('/etats-des-lieux/${widget.id}', body: c),
      ),
    );
    if (r != null) _charger();
  }

  Future<void> _ajouterPiece() async {
    final ctrl = TextEditingController();
    final nom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle pièce'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nom', hintText: 'Ex. Chambre 2')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );
    if (nom == null || nom.isEmpty || !mounted) return;
    await executer(
      context,
      () => api.post<dynamic>('/etats-des-lieux/${widget.id}/pieces', body: {
        'name': nom,
        'items': [for (final el in ['murs', 'sols', 'plafond', 'portes', 'fenetres', 'electricite']) {'element': el}],
      }),
      succes: 'Pièce ajoutée',
    );
    _charger();
  }

  /// Saisie d'un texte court (nom de pièce, libellé d'élément). Renvoie null si annulé.
  Future<String?> _saisirTexte(String titre, String libelle, {String? initial, int maxLongueur = 80, bool obligatoire = true}) {
    final ctrl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: TextField(controller: ctrl, autofocus: true, maxLength: maxLongueur, decoration: InputDecoration(labelText: libelle)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (obligatoire && v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _renommerPiece(Map piece) async {
    final nom = await _saisirTexte('Renommer la pièce', 'Nom', initial: '${piece['name'] ?? ''}');
    if (nom == null || nom == piece['name'] || !mounted) return;
    await executer(context, () => api.patch<dynamic>('/etats-des-lieux/${widget.id}/pieces/${piece['id']}', body: {'name': nom}),
        succes: 'Pièce renommée');
    _charger();
  }

  Future<void> _supprimerPiece(Map piece) async {
    final ok = await confirmer(context,
        titre: 'Supprimer la pièce', message: 'Ses éléments et leurs photos seront supprimés.', action: 'Supprimer', danger: true);
    if (ok == null || !mounted) return;
    final r = await executer(context, () => api.delete<dynamic>('/etats-des-lieux/${widget.id}/pieces/${piece['id']}').then((_) => true),
        succes: 'Pièce supprimée');
    if (r != true || !mounted) return;
    for (final it in ((piece['items'] as List?) ?? []).cast<Map>()) {
      _saisies.remove('${it['id']}');
    }
    _charger();
  }

  Future<void> _ajouterElement(Map piece) async {
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Nouvel élément · ${piece['name']}',
        champs: const [
          Champ('element', 'Élément', type: TypeChamp.selection, referentiel: 'element_etat_des_lieux', obligatoire: true),
          Champ('label', 'Précision (facultatif)', maxLongueur: 120, indice: 'Ex. Placard mural'),
        ],
        messageSucces: 'Élément ajouté',
        envoyer: (c) => api.post<Map<String, dynamic>>('/etats-des-lieux/${widget.id}/pieces/${piece['id']}/elements', body: c),
      ),
    );
    if (r != null) _charger();
  }

  Future<void> _libelleElement(Map item) async {
    final libelle = await _saisirTexte("Précision de l'élément", 'Précision', initial: item['label'] as String?, maxLongueur: 120, obligatoire: false);
    if (libelle == null || libelle == (item['label'] ?? '') || !mounted) return;
    await executer(context,
        () => api.patch<dynamic>('/etats-des-lieux/${widget.id}/elements/${item['id']}', body: {'label': libelle.isEmpty ? null : libelle}),
        succes: 'Élément modifié');
    _charger();
  }

  Future<void> _supprimerElement(Map item) async {
    final ok = await confirmer(context,
        titre: "Supprimer l'élément", message: 'Ses photos seront supprimées.', action: 'Supprimer', danger: true);
    if (ok == null || !mounted) return;
    final r = await executer(context, () => api.delete<dynamic>('/etats-des-lieux/${widget.id}/elements/${item['id']}').then((_) => true),
        succes: 'Élément supprimé');
    if (r != true || !mounted) return;
    _saisies.remove('${item['id']}');
    _charger();
  }

  Future<void> _supprimerPhoto(Map photo) async {
    final ok = await confirmer(context, titre: 'Retirer la photo', message: 'La photo sera supprimée.', action: 'Retirer', danger: true);
    if (ok == null || !mounted) return;
    final r = await executer(context, () => api.delete<dynamic>('/etats-des-lieux/${widget.id}/photos/${photo['id']}').then((_) => true),
        succes: 'Photo retirée');
    if (r == true) _charger();
  }

  Future<void> _photo(Map item) async {
    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;
    // Horodatage de la prise de vue ET horodatage serveur conservés (§ 52.4)
    await executer(
      context,
      () => api.upload<dynamic>('/etats-des-lieux/${widget.id}/elements/${item['id']}/photos',
          cheminFichier: photo.path, champs: {'captured_at': DateTime.now().toUtc().toIso8601String()}, idempotence: nouvelleCle()),
      succes: 'Photo ajoutée',
    );
    _charger();
  }

  Future<void> _soumettre() async {
    if (!await _enregistrer() || !mounted) return;
    final ok = await confirmer(context,
        titre: 'Soumettre au locataire',
        message: "Le locataire pourra l'accepter ou le contester dans le délai prévu ; sans réponse, il est accepté tacitement. "
            'Il ne pourra plus être modifié (une correction crée une nouvelle version).',
        action: 'Soumettre');
    if (ok == null || !mounted) return;
    await executer(context, () => api.post<dynamic>('/etats-des-lieux/${widget.id}/soumettre'), succes: 'État des lieux soumis');
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final e = _edl;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('État des lieux')),
        body: _erreur != null ? VueErreur(_erreur!, onReessayer: _charger) : const Center(child: CircularProgressIndicator()),
      );
    }
    final statut = e['status'] as String;
    final pieces = ((e['rooms'] as List?) ?? []).cast<Map>();
    final etats = refs.options('etat_element');
    return PopScope(
      canPop: _saisies.isEmpty,
      onPopInvokedWithResult: (sorti, _) async {
        if (sorti) return;
        final quitter = await confirmer(context,
            titre: 'Saisies non enregistrées', message: 'Enregistrer vos modifications avant de quitter ?', action: 'Enregistrer');
        if (!mounted) return;
        if (quitter != null) await _enregistrer();
        if (!mounted) return;
        setState(_saisies.clear);
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${refs.libelle('type_etat_des_lieux', e['type'] as String?)} · v${e['version']}'),
          actions: [
            IconButton(
              tooltip: 'PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => ouvrirPdf(context, '/etats-des-lieux/${widget.id}/pdf', 'etat-des-lieux-${e['type']}-v${e['version']}.pdf'),
            ),
            MenuActions(actions: [
              if (_modifiable) ('Relevés et observations', _general, false),
              if (_modifiable) ('Ajouter une pièce', _ajouterPiece, false),
              if (statut == 'accepte' || statut == 'conteste')
                ('Corriger (nouvelle version)', () async {
                  final r = await executer(context, () => api.post<Map<String, dynamic>>('/etats-des-lieux/${widget.id}/corriger', idempotence: nouvelleCle()),
                      succes: 'Nouvelle version créée');
                  if (r != null && context.mounted) {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => EtatDesLieuxDetail(id: '${(r['inspection'] as Map)['id']}')));
                  }
                }, false),
              if (_modifiable)
                ('Supprimer le brouillon', () async {
                  final ok = await confirmer(context, titre: 'Supprimer le brouillon', message: 'Toutes les saisies seront perdues.', danger: true, action: 'Supprimer');
                  if (ok == null || !context.mounted) return;
                  final fait = await executer(context, () => api.delete<dynamic>('/etats-des-lieux/${widget.id}').then((_) => true), succes: 'Brouillon supprimé');
                  if (fait == true && context.mounted) Navigator.pop(context);
                }, true),
            ]),
          ],
        ),
        bottomNavigationBar: _modifiable
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _envoi || _saisies.isEmpty ? null : _enregistrer,
                        child: Text(_saisies.isEmpty ? 'Enregistré' : 'Enregistrer (${_saisies.length})'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: FilledButton(onPressed: _envoi ? null : _soumettre, child: const Text('Soumettre'))),
                  ]),
                ),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _charger,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Row(children: [
                Expanded(
                    child: Text('${nomComplet(e['tenant'] as Map?)} · Appartement ${(e['apartment'] as Map?)?['number'] ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium)),
                Statut(FamilleStatut.etatDesLieux, 'statut_etat_des_lieux', statut),
              ]),
              const SizedBox(height: AppTheme.espaceSm),
              Ligne('Date', date(e['performed_at'] as String?)),
              Ligne('Compteur d’eau', e['water_meter'] == null ? null : '${e['water_meter']} m³'),
              Ligne('Compteur d’électricité', e['electricity_meter'] == null ? null : '${e['electricity_meter']} kWh'),
              Ligne('Clés', e['keys_count'] == null ? null : '${e['keys_count']}${e['keys_details'] != null ? ' · ${e['keys_details']}' : ''}'),
              if (e['general_observations'] != null) Ligne('Observations', '${e['general_observations']}'),
              if (e['response_deadline'] != null && statut == 'soumis') Ligne('Réponse attendue avant le', dateHeure(e['response_deadline'] as String?)),
              if (e['accepted_tacitly'] == true) const Ligne('Acceptation', 'Tacite (délai écoulé)'),
              if (e['contest_comment'] != null) ...[
                const SizedBox(height: 8),
                Encadre('Contestation du locataire : « ${e['contest_comment']} »', ton: TonStatut.danger),
              ],
            ]),
            const SizedBox(height: AppTheme.espaceLg),
            for (final p in pieces) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text('${p['name']}'),
                  subtitle: Text('${((p['items'] as List?) ?? []).length} élément(s)'),
                  trailing: _modifiable
                      ? PopupMenuButton<String>(
                          tooltip: 'Actions sur la pièce',
                          onSelected: (a) => switch (a) {
                            'element' => _ajouterElement(p),
                            'renommer' => _renommerPiece(p),
                            _ => _supprimerPiece(p),
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'element', child: Text('Ajouter un élément')),
                            PopupMenuItem(value: 'renommer', child: Text('Renommer')),
                            PopupMenuItem(value: 'supprimer', child: Text('Supprimer la pièce')),
                          ],
                        )
                      : null,
                  children: [
                    for (final it in ((p['items'] as List?) ?? []).cast<Map>())
                      _Element(
                        item: it,
                        etats: etats,
                        modifiable: _modifiable,
                        saisie: _saisies['${it['id']}'],
                        onChange: (etat, commentaire) => setState(() => _saisies['${it['id']}'] = (etat, commentaire)),
                        onPhoto: () => _photo(it),
                        onLibelle: () => _libelleElement(it),
                        onSupprimer: () => _supprimerElement(it),
                        onSupprimerPhoto: _supprimerPhoto,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.espaceSm),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Element extends StatelessWidget {
  const _Element({
    required this.item,
    required this.etats,
    required this.modifiable,
    this.saisie,
    required this.onChange,
    required this.onPhoto,
    required this.onLibelle,
    required this.onSupprimer,
    required this.onSupprimerPhoto,
  });
  final Map item;
  final List<OptionRef> etats;
  final bool modifiable;
  final (String, String?)? saisie;
  final void Function(String etat, String? commentaire) onChange;
  final VoidCallback onPhoto;
  final VoidCallback onLibelle;
  final VoidCallback onSupprimer;
  final void Function(Map photo) onSupprimerPhoto;

  @override
  Widget build(BuildContext context) {
    final etat = saisie?.$1 ?? item['condition'] as String?;
    final commentaire = saisie?.$2 ?? item['comment'] as String?;
    final photos = ((item['photos'] as List?) ?? []).cast<Map>();
    final libelle = '${refs.libelle('element_etat_des_lieux', item['element'] as String?)}${item['label'] != null ? ' · ${item['label']}' : ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(libelle, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (modifiable) IconButton(tooltip: 'Photo', onPressed: onPhoto, icon: const Icon(Icons.add_a_photo_outlined, size: 20)),
          if (modifiable)
            PopupMenuButton<String>(
              tooltip: "Actions sur l'élément",
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (a) => a == 'libelle' ? onLibelle() : onSupprimer(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'libelle', child: Text('Modifier la précision')),
                PopupMenuItem(value: 'supprimer', child: Text("Supprimer l'élément")),
              ],
            ),
        ]),
        if (modifiable)
          Wrap(spacing: 6, children: [
            for (final o in etats)
              ChoiceChip(label: Text(o.label), selected: etat == o.code, onSelected: (_) => onChange(o.code, commentaire)),
          ])
        else
          Text(etat == null ? 'Non renseigné' : refs.libelle('etat_element', etat)),
        if (modifiable)
          TextFormField(
            initialValue: commentaire,
            decoration: const InputDecoration(isDense: true, hintText: 'Commentaire'),
            maxLength: 2000,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            onChanged: (v) => onChange(etat ?? 'bon', v.trim().isEmpty ? null : v.trim()),
          )
        else if (commentaire != null)
          Text(commentaire, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final ph in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => afficherImage(context, '${(ph['document'] as Map)['id']}'),
                    onLongPress: modifiable ? () => onSupprimerPhoto(ph) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
                      child: SizedBox(width: 64, height: 64, child: ImageApi('${(ph['document'] as Map)['id']}')),
                    ),
                  ),
                ),
            ]),
          ),
        ],
        if (modifiable && etat == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('À renseigner', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
      ]),
    );
  }
}

/// Comparaison entrée / sortie (§ 52.3) : éléments dégradés, absents, nouveaux.
class ComparaisonEdl extends StatelessWidget {
  const ComparaisonEdl({super.key, required this.bailId});
  final String bailId;

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Comparaison',
      charger: () => api.get<Map<String, dynamic>>('/etats-des-lieux/comparaison', query: {'lease_id': bailId}),
      builder: (context, data, _) {
        final c = data['comparaison'] as Map;
        final resume = c['resume'] as Map;
        final ecarts = ((c['ecarts'] as List?) ?? []).cast<Map>();
        return Scaffold(
          appBar: AppBar(title: const Text('Entrée / sortie')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Ligne('Éléments comparés', '${resume['elements_sortie']}'),
              Ligne('Identiques', '${resume['identiques']}'),
              Ligne('Dégradés', '${resume['ecarts']}'),
              Ligne('Améliorés', '${resume['ameliores']}'),
              Ligne('Absents à la sortie', '${resume['absents']}'),
            ]),
            const SizedBox(height: 16),
            if (ecarts.isEmpty) const Vide('Aucune dégradation constatée', icone: Icons.verified_outlined),
            for (final e in ecarts)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${e['piece']} · ${e['element_libelle']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Entrée : ${(e['entree'] as Map?)?['condition_libelle'] ?? '—'}  →  Sortie : ${(e['sortie'] as Map?)?['condition_libelle'] ?? '—'}'),
                    if ((e['sortie'] as Map?)?['comment'] != null) Text('« ${(e['sortie'] as Map)['comment']} »'),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}
