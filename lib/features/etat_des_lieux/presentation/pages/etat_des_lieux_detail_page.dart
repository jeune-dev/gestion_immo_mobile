import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/usecases/modifier_releves_edl.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/usecases/telecharger_pdf_edl.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/bloc/etat_des_lieux_bloc.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/bloc/etat_des_lieux_event.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/bloc/etat_des_lieux_state.dart';

class EtatDesLieuxDetailPage extends StatelessWidget {
  final String id;
  const EtatDesLieuxDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<EtatDesLieuxBloc>()..add(LoadEtatDesLieux(id)),
      child: _Detail(id: id),
    );
  }
}

class _Detail extends StatefulWidget {
  final String id;
  const _Detail({required this.id});

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  /// Saisies non encore envoyées : élément → (état, commentaire).
  final Map<String, (String, String?)> _saisies = {};
  bool _envoi = false;

  EtatDesLieuxBloc get _bloc => context.read<EtatDesLieuxBloc>();

  /// Enregistre toutes les saisies en une requête (§ 52.4, saisie synchronisée).
  Future<bool> _enregistrer() async {
    if (_saisies.isEmpty) return true;
    setState(() => _envoi = true);
    final echec = await _bloc.enregistrerSaisie(widget.id, [
      for (final e in _saisies.entries)
        {'item_id': e.key, 'condition': e.value.$1, 'comment': e.value.$2},
    ]);
    if (!mounted) return false;
    setState(() => _envoi = false);
    if (echec != null) {
      afficherErreurApi(context, echec);
      return false;
    }
    afficherSucces(context, 'Saisie enregistrée');
    setState(_saisies.clear);
    return true;
  }

  Future<void> _releves(EtatDesLieux e) async {
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Relevés et observations',
        initial: {
          'water_meter': e.compteurEau,
          'electricity_meter': e.compteurElectricite,
          'keys_count': e.nbCles,
          'keys_details': e.detailCles,
          'general_observations': e.observations,
        },
        champs: const [
          Champ('water_meter', 'Compteur d’eau (m³)',
              type: TypeChamp.decimal, nullable: true),
          Champ('electricity_meter', 'Compteur d’électricité (kWh)',
              type: TypeChamp.decimal, nullable: true),
          Champ('keys_count', 'Nombre de clés remises',
              type: TypeChamp.entier, min: 0, max: 100, nullable: true),
          Champ('keys_details', 'Détail des clés', maxLongueur: 2000),
          Champ('general_observations', 'Observations générales',
              type: TypeChamp.multiligne, maxLongueur: 5000),
        ],
        messageSucces: 'Enregistré',
        envoyer: (c) async {
          final r = await di.sl<ModifierRelevesEdl>()(widget.id, c);
          return r.fold((f) => throw f, (_) => true);
        },
      ),
    );
    if (r != null) _bloc.add(RafraichirEtatDesLieux(widget.id));
  }

  /// Saisie d'un texte court (nom de pièce, précision d'élément). Renvoie null si annulé.
  Future<String?> _saisirTexte(String titre, String libelle,
      {String? initial, int maxLongueur = 80, bool obligatoire = true}) {
    final ctrl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: maxLongueur,
          decoration: InputDecoration(labelText: libelle),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
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

  Future<void> _ajouterPiece() async {
    final nom = await _saisirTexte('Nouvelle pièce', 'Nom', maxLongueur: 80);
    if (nom != null && nom.isNotEmpty) {
      _bloc.add(AjouterPieceEvent(widget.id, nom));
    }
  }

  Future<void> _renommerPiece(PieceEdl piece) async {
    final nom =
        await _saisirTexte('Renommer la pièce', 'Nom', initial: piece.nom);
    if (nom != null && nom != piece.nom) {
      _bloc.add(RenommerPieceEvent(widget.id, piece.id, nom));
    }
  }

  Future<void> _supprimerPiece(PieceEdl piece) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer la pièce',
      message: 'Ses éléments et leurs photos seront supprimés.',
      action: 'Supprimer',
      danger: true,
    );
    if (ok == null) return;
    for (final el in piece.elements) {
      _saisies.remove(el.id);
    }
    _bloc.add(SupprimerPieceEvent(widget.id, piece.id));
  }

  Future<void> _ajouterElement(PieceEdl piece) async {
    final r = await EcranFormulaire.ouvrir<Map<String, dynamic>>(
      context,
      EcranFormulaire(
        titre: 'Nouvel élément · ${piece.nom}',
        champs: const [
          Champ('element', 'Élément',
              type: TypeChamp.selection,
              referentiel: 'element_etat_des_lieux',
              obligatoire: true),
          Champ('label', 'Précision (facultatif)',
              maxLongueur: 120, indice: 'Ex. Placard mural'),
        ],
        envoyer: (c) async => c,
      ),
    );
    if (r != null) _bloc.add(AjouterElementEvent(widget.id, piece.id, r));
  }

  Future<void> _preciserElement(ElementEdl el) async {
    final precision = await _saisirTexte("Précision de l'élément", 'Précision',
        initial: el.precision, maxLongueur: 120, obligatoire: false);
    if (precision == null || precision == (el.precision ?? '')) return;
    _bloc.add(PreciserElementEvent(
        widget.id, el.id, precision.isEmpty ? null : precision));
  }

  Future<void> _supprimerElement(ElementEdl el) async {
    final ok = await confirmer(context,
        titre: "Supprimer l'élément",
        message: 'Ses photos seront supprimées.',
        action: 'Supprimer',
        danger: true);
    if (ok == null) return;
    _saisies.remove(el.id);
    _bloc.add(SupprimerElementEvent(widget.id, el.id));
  }

  Future<void> _photo(ElementEdl el) async {
    final photo = await choisirPhoto(context);
    if (photo != null) {
      _bloc.add(AjouterPhotoEvent(widget.id, el.id, photo.path));
    }
  }

  Future<void> _supprimerPhoto(PhotoEdl photo) async {
    final ok = await confirmer(context,
        titre: 'Retirer la photo',
        message: 'La photo sera supprimée.',
        action: 'Retirer',
        danger: true);
    if (ok != null) _bloc.add(SupprimerPhotoEvent(widget.id, photo.id));
  }

  Future<void> _soumettre() async {
    if (!await _enregistrer() || !mounted) return;
    final ok = await confirmer(
      context,
      titre: 'Soumettre au locataire',
      message:
          "Le locataire pourra l'accepter ou le contester dans le délai prévu ; sans réponse, il est accepté tacitement. "
          'Il ne pourra plus être modifié (une correction crée une nouvelle version).',
      action: 'Soumettre',
    );
    if (ok != null) _bloc.add(SoumettreEtatDesLieuxEvent(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EtatDesLieuxBloc, EtatDesLieuxState>(
      listener: (context, state) {
        if (state is EtatDesLieuxSuccess) {
          afficherSucces(context, state.message);
        } else if (state is EtatDesLieuxActionError) {
          afficherErreurApi(context, state.failure);
        } else if (state is EtatDesLieuxSupprime) {
          afficherSucces(context, state.message);
          Navigator.of(context).pop(true);
        } else if (state is NouvelleVersionLoaded) {
          // Correction : on bascule sur la nouvelle version (brouillon)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EtatDesLieuxDetailPage(id: state.version.id),
            ),
          );
        }
      },
      // Les états d'action (message…) ne redessinent pas l'écran.
      buildWhen: (_, state) =>
          state is EtatDesLieuxInitial ||
          state is EtatDesLieuxLoading ||
          state is EtatDesLieuxLoaded ||
          state is EtatDesLieuxError,
      builder: (context, state) {
        if (state is EtatDesLieuxLoaded) {
          return _fiche(context, state.etatDesLieux);
        }
        return VueChargement(
          titre: 'État des lieux',
          failure: state is EtatDesLieuxError ? state.failure : null,
          onReessayer: () => _bloc.add(LoadEtatDesLieux(widget.id)),
        );
      },
    );
  }

  Widget _fiche(BuildContext context, EtatDesLieux e) {
    final statut = e.statut;
    final etats = refs.options('etat_element');
    return PopScope(
      canPop: _saisies.isEmpty,
      onPopInvokedWithResult: (sorti, _) async {
        if (sorti) return;
        final quitter = await confirmer(
          context,
          titre: 'Saisies non enregistrées',
          message: 'Enregistrer vos modifications avant de quitter ?',
          action: 'Enregistrer',
        );
        if (!mounted) return;
        if (quitter != null) await _enregistrer();
        if (!mounted) return;
        setState(_saisies.clear);
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              '${refs.libelle('type_etat_des_lieux', e.type)} · v${e.version ?? ''}'),
          actions: [
            IconButton(
              tooltip: 'PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => ouvrirPdf(
                  context,
                  () => di.sl<TelechargerPdfEdl>()(widget.id),
                  'etat-des-lieux-${e.type}-v${e.version}.pdf'),
            ),
            MenuActions(
              actions: [
                if (e.modifiable)
                  ('Relevés et observations', () => _releves(e), false),
                if (e.modifiable) ('Ajouter une pièce', _ajouterPiece, false),
                if (statut == 'accepte' || statut == 'conteste')
                  (
                    'Corriger (nouvelle version)',
                    () => _bloc.add(CorrigerEtatDesLieuxEvent(widget.id)),
                    false
                  ),
                if (e.modifiable)
                  (
                    'Supprimer le brouillon',
                    () async {
                      final ok = await confirmer(
                        context,
                        titre: 'Supprimer le brouillon',
                        message: 'Toutes les saisies seront perdues.',
                        danger: true,
                        action: 'Supprimer',
                      );
                      if (ok == null) return;
                      setState(_saisies.clear);
                      _bloc.add(SupprimerEtatDesLieuxEvent(widget.id));
                    },
                    true,
                  ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: e.modifiable
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _envoi || _saisies.isEmpty ? null : _enregistrer,
                          child: Text(_saisies.isEmpty
                              ? 'Enregistré'
                              : 'Enregistrer (${_saisies.length})'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                            onPressed: _envoi ? null : _soumettre,
                            child: const Text('Soumettre')),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async => _bloc.add(RafraichirEtatDesLieux(widget.id)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Section(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${nomDe(e.locataire)} · Appartement ${e.appartementNumero ?? ''}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Statut(FamilleStatut.etatDesLieux,
                          'statut_etat_des_lieux', statut),
                    ],
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  Ligne('Date', date(e.realiseLe)),
                  Ligne('Compteur d’eau',
                      e.compteurEau == null ? null : '${e.compteurEau} m³'),
                  Ligne(
                      'Compteur d’électricité',
                      e.compteurElectricite == null
                          ? null
                          : '${e.compteurElectricite} kWh'),
                  Ligne(
                      'Clés',
                      e.nbCles == null
                          ? null
                          : '${e.nbCles}${e.detailCles != null ? ' · ${e.detailCles}' : ''}'),
                  if (e.observations != null)
                    Ligne('Observations', e.observations),
                  if (e.limiteReponse != null && statut == 'soumis')
                    Ligne('Réponse attendue avant le',
                        dateHeure(e.limiteReponse)),
                  if (e.accepteTacitement)
                    const Ligne('Acceptation', 'Tacite (délai écoulé)'),
                  if (e.contestation != null) ...[
                    const SizedBox(height: 8),
                    Encadre('Contestation du locataire : « ${e.contestation} »',
                        ton: TonStatut.danger),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.espaceLg),
              for (final p in e.pieces) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    title: Text(p.nom),
                    subtitle: Text('${p.elements.length} élément(s)'),
                    trailing: e.modifiable
                        ? PopupMenuButton<String>(
                            tooltip: 'Actions sur la pièce',
                            onSelected: (a) => switch (a) {
                              'element' => _ajouterElement(p),
                              'renommer' => _renommerPiece(p),
                              _ => _supprimerPiece(p),
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'element',
                                  child: Text('Ajouter un élément')),
                              PopupMenuItem(
                                  value: 'renommer', child: Text('Renommer')),
                              PopupMenuItem(
                                  value: 'supprimer',
                                  child: Text('Supprimer la pièce')),
                            ],
                          )
                        : null,
                    children: [
                      for (final el in p.elements)
                        _Element(
                          element: el,
                          etats: etats,
                          modifiable: e.modifiable,
                          saisie: _saisies[el.id],
                          onChange: (etat, commentaire) => setState(
                              () => _saisies[el.id] = (etat, commentaire)),
                          onPhoto: () => _photo(el),
                          onPreciser: () => _preciserElement(el),
                          onSupprimer: () => _supprimerElement(el),
                          onSupprimerPhoto: _supprimerPhoto,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.espaceSm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Element extends StatelessWidget {
  final ElementEdl element;
  final List<OptionRef> etats;
  final bool modifiable;

  final (String, String?)? saisie;
  final void Function(String etat, String? commentaire) onChange;
  final VoidCallback onPhoto;
  final VoidCallback onPreciser;
  final VoidCallback onSupprimer;
  final void Function(PhotoEdl photo) onSupprimerPhoto;

  const _Element({
    required this.element,
    required this.etats,
    required this.modifiable,
    this.saisie,
    required this.onChange,
    required this.onPhoto,
    required this.onPreciser,
    required this.onSupprimer,
    required this.onSupprimerPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final etat = saisie?.$1 ?? element.etat;
    final commentaire = saisie?.$2 ?? element.commentaire;
    final libelle =
        '${refs.libelle('element_etat_des_lieux', element.element)}${element.precision != null ? ' · ${element.precision}' : ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(libelle,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (modifiable)
                IconButton(
                    tooltip: 'Photo',
                    onPressed: onPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 20)),
              if (modifiable)
                PopupMenuButton<String>(
                  tooltip: "Actions sur l'élément",
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (a) =>
                      a == 'libelle' ? onPreciser() : onSupprimer(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'libelle', child: Text('Modifier la précision')),
                    PopupMenuItem(
                        value: 'supprimer', child: Text("Supprimer l'élément")),
                  ],
                ),
            ],
          ),
          if (modifiable)
            Wrap(
              spacing: 6,
              children: [
                for (final o in etats)
                  ChoiceChip(
                      label: Text(o.label),
                      selected: etat == o.code,
                      onSelected: (_) => onChange(o.code, commentaire)),
              ],
            )
          else
            Text(etat == null
                ? 'Non renseigné'
                : refs.libelle('etat_element', etat)),
          if (modifiable)
            TextFormField(
              initialValue: commentaire,
              decoration:
                  const InputDecoration(isDense: true, hintText: 'Commentaire'),
              maxLength: 2000,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              onChanged: (v) =>
                  onChange(etat ?? 'bon', v.trim().isEmpty ? null : v.trim()),
            )
          else if (commentaire != null)
            Text(commentaire,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (element.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final ph in element.photos)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => afficherImage(context, ph.document.id),
                        onLongPress:
                            modifiable ? () => onSupprimerPhoto(ph) : null,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.rayonPetit),
                          child: SizedBox(
                              width: 64,
                              height: 64,
                              child: ImageApi(ph.document.id)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (modifiable && etat == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('À renseigner',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

/// Ouvre la fiche (listes, bail).
Future<void> ouvrirEtatDesLieux(BuildContext context, String id) =>
    ouvrir(context, EtatDesLieuxDetailPage(id: id));
