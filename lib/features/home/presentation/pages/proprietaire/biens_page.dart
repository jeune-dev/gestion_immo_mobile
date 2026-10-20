import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/usecases/get_appartements.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/formulaire_appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/tuile_appartement.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/get_baux.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/formulaire_bail.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/widgets/tuile_bail.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/entities/immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/usecases/get_immeubles.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/pages/immeuble_detail_page.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/formulaire_immeuble.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/entities/locataire.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/usecases/get_locataires.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/pages/locataire_detail_page.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/widgets/dialogue_invitation.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/widgets/formulaire_locataire.dart';

/// Onglet « Biens » : immeubles, appartements, locataires, baux.
class BiensPage extends StatefulWidget {
  const BiensPage({super.key});

  @override
  State<BiensPage> createState() => _BiensPageState();
}

class _BiensPageState extends State<BiensPage>
    with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 4, vsync: this)
    ..addListener(() => setState(() {}));
  final _immeubles = GlobalKey<ListePagineeState<Immeuble>>();
  final _appartements = GlobalKey<ListePagineeState<Appartement>>();
  final _locataires = GlobalKey<ListePagineeState<Locataire>>();
  final _baux = GlobalKey<ListePagineeState<Bail>>();
  String _q = '';

  void _rafraichir() => switch (_onglets.index) {
        0 => _immeubles.currentState?.recharger(),
        1 => _appartements.currentState?.recharger(),
        2 => _locataires.currentState?.recharger(),
        _ => _baux.currentState?.recharger(),
      };

  Future<Object?> _formulaire() => switch (_onglets.index) {
        0 => formulaireImmeuble(context),
        1 => formulaireAppartement(context),
        2 => creerLocataire(context),
        _ => formulaireBail(context),
      };

  Future<void> _ajouter() async {
    final r = await _formulaire();
    if (r == null) return;
    // Locataire créé avec invitation : le code est à transmettre tout de suite
    if (r is LocataireCree && r.invitation != null && mounted) {
      await afficherInvitation(context, r.invitation!, r.locataire);
    }
    _rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.isEmpty ? null : _q;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes biens'),
        bottom: TabBar(
          controller: _onglets,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(context)
              .appBarTheme
              .foregroundColor
              ?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(text: 'Immeubles'),
            Tab(text: 'Appartements'),
            Tab(text: 'Locataires'),
            Tab(text: 'Baux'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: Text(
            ['Immeuble', 'Appartement', 'Locataire', 'Bail'][_onglets.index]),
      ),
      body: Column(
        children: [
          if (_onglets.index < 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher',
                    isDense: true),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => setState(() => _q = v.trim()),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _onglets,
              children: [
                ListePaginee<Immeuble>(
                  key: _immeubles,
                  cle: q,
                  vide:
                      'Aucun immeuble. Commencez par créer votre premier immeuble.',
                  iconeVide: Icons.apartment_outlined,
                  charger: (page) =>
                      sl<GetImmeubles>()(page: page, recherche: q),
                  element: (context, b) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.apartment)),
                    title: Text(b.nom),
                    subtitle: Text(
                        '${b.ville ?? ''} · ${b.nbAppartements} appart. · ${b.nbOccupes} occupés'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await ouvrirImmeuble(context, b.id);
                      _immeubles.currentState?.recharger();
                    },
                  ),
                ),
                _ListeAppartements(cle: _appartements, q: q),
                ListePaginee<Locataire>(
                  key: _locataires,
                  cle: q,
                  vide: 'Aucun locataire',
                  iconeVide: Icons.people_outline,
                  charger: (page) =>
                      sl<GetLocataires>()(page: page, recherche: q),
                  element: (context, t) => ListTile(
                    leading: CircleAvatar(
                        child: Text(t.initiales.isEmpty ? '?' : t.initiales)),
                    title: Text(t.nomComplet),
                    subtitle: Text(
                      [
                        t.telephone,
                        if (t.logementCourant != null)
                          'Appart. ${t.logementCourant!.numero}'
                        else
                          'Sans bail actif',
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: t.compteActif
                        ? Icon(Icons.verified_user_outlined,
                            color: context.palette.succes,
                            semanticLabel: 'Compte activé')
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      await ouvrir(context, LocataireDetailPage(id: t.id));
                      _locataires.currentState?.recharger();
                    },
                  ),
                ),
                _ListeBaux(cle: _baux),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeAppartements extends StatefulWidget {
  final GlobalKey<ListePagineeState<Appartement>> cle;
  final String? q;
  const _ListeAppartements({required this.cle, this.q});

  @override
  State<_ListeAppartements> createState() => _ListeAppartementsState();
}

class _ListeAppartementsState extends State<_ListeAppartements> {
  String _statut = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Filtres(
          options: [
            ('', 'Tous'),
            for (final o in refs.options('statut_appartement'))
              (o.code, o.label)
          ],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee<Appartement>(
            key: widget.cle,
            cle: '${widget.q}|$_statut',
            vide: 'Aucun appartement',
            iconeVide: Icons.door_front_door_outlined,
            charger: (page) => sl<GetAppartements>()(
                page: page,
                recherche: widget.q,
                statut: _statut.isEmpty ? null : _statut),
            element: (context, a) => TuileAppartement(
                a: a, onRetour: () => widget.cle.currentState?.recharger()),
          ),
        ),
      ],
    );
  }
}

class _ListeBaux extends StatefulWidget {
  final GlobalKey<ListePagineeState<Bail>> cle;
  const _ListeBaux({required this.cle});

  @override
  State<_ListeBaux> createState() => _ListeBauxState();
}

class _ListeBauxState extends State<_ListeBaux> {
  String _statut = 'actif';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Filtres(
          options: [
            ('', 'Tous'),
            for (final o in refs.options('statut_bail')) (o.code, o.label)
          ],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee<Bail>(
            key: widget.cle,
            cle: _statut,
            vide: 'Aucun bail',
            iconeVide: Icons.description_outlined,
            charger: (page) => sl<GetBaux>()(
                page: page, statut: _statut.isEmpty ? null : _statut),
            element: (context, b) => TuileBail(
                b: b, onRetour: () => widget.cle.currentState?.recharger()),
          ),
        ),
      ],
    );
  }
}
