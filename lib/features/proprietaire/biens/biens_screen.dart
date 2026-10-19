import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/statuts.dart';
import 'appartement_detail.dart';
import 'bail_detail.dart';
import 'formulaires.dart';
import 'immeuble_detail.dart';
import 'locataire_detail.dart';

/// Onglet « Biens » : immeubles, appartements, locataires, baux.
class BiensScreen extends StatefulWidget {
  const BiensScreen({super.key});

  @override
  State<BiensScreen> createState() => _BiensScreenState();
}

class _BiensScreenState extends State<BiensScreen> with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));
  final _cles = List.generate(4, (_) => GlobalKey<ListePagineeState>());
  String _q = '';

  void _rafraichir() => _cles[_onglets.index].currentState?.recharger();

  Future<void> _ajouter() async {
    final r = await switch (_onglets.index) {
      0 => FormulairesBiens.immeuble(context),
      1 => FormulairesBiens.appartement(context),
      2 => FormulairesBiens.locataire(context),
      _ => FormulairesBiens.bail(context),
    };
    if (r == null) return;
    // Locataire créé avec invitation : le code est à transmettre tout de suite
    if (_onglets.index == 2 && r['invitation'] != null && mounted) {
      await LocataireDetail.afficherInvitation(context, r['invitation'] as Map, r['tenant'] as Map);
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
          unselectedLabelColor: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [Tab(text: 'Immeubles'), Tab(text: 'Appartements'), Tab(text: 'Locataires'), Tab(text: 'Baux')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: Text(['Immeuble', 'Appartement', 'Locataire', 'Bail'][_onglets.index]),
      ),
      body: Column(children: [
        if (_onglets.index < 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher', isDense: true),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() => _q = v.trim()),
            ),
          ),
        Expanded(
          child: TabBarView(controller: _onglets, children: [
            ListePaginee(
              key: _cles[0],
              cle: q,
              vide: 'Aucun immeuble. Commencez par créer votre premier immeuble.',
              iconeVide: Icons.apartment_outlined,
              charger: (page) => api.get('/immeubles', query: {'page': page, 'q': q, 'tri': 'name'}),
              element: (context, b) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.apartment)),
                title: Text('${b['name']}'),
                subtitle: Text('${b['city']} · ${b['apartments_count']} appart. · ${b['occupied_count']} occupés'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await ouvrir(context, ImmeubleDetail(id: '${b['id']}'));
                  _cles[0].currentState?.recharger();
                },
              ),
            ),
            _ListeAppartements(cle: _cles[1], q: q),
            ListePaginee(
              key: _cles[2],
              cle: q,
              vide: 'Aucun locataire',
              iconeVide: Icons.people_outline,
              charger: (page) => api.get('/locataires', query: {'page': page, 'q': q, 'tri': 'last_name'}),
              element: (context, t) {
                final bail = t['current_lease'] as Map?;
                return ListTile(
                  leading: CircleAvatar(child: Text(initiales(t))),
                  title: Text(nomComplet(t)),
                  subtitle: Text([
                    t['phone'],
                    if (bail != null) 'Appart. ${(bail['apartment'] as Map?)?['number'] ?? ''}' else 'Sans bail actif',
                  ].whereType<String>().join(' · ')),
                  trailing: t['account_active'] == true
                      ? Icon(Icons.verified_user_outlined, color: context.palette.succes, semanticLabel: 'Compte activé')
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    await ouvrir(context, LocataireDetail(id: '${t['id']}'));
                    _cles[2].currentState?.recharger();
                  },
                );
              },
            ),
            _ListeBaux(cle: _cles[3]),
          ]),
        ),
      ]),
    );
  }
}

class _ListeAppartements extends StatefulWidget {
  const _ListeAppartements({required this.cle, this.q});
  final GlobalKey<ListePagineeState> cle;
  final String? q;

  @override
  State<_ListeAppartements> createState() => _ListeAppartementsState();
}

class _ListeAppartementsState extends State<_ListeAppartements> {
  String _statut = '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Filtres(
        options: [('', 'Tous'), for (final o in refs.options('statut_appartement')) (o.code, o.label)],
        valeur: _statut,
        onChange: (v) => setState(() => _statut = v),
      ),
      Expanded(
        child: ListePaginee(
          key: widget.cle,
          cle: '${widget.q}|$_statut',
          vide: 'Aucun appartement',
          iconeVide: Icons.door_front_door_outlined,
          charger: (page) => api.get('/appartements', query: {'page': page, 'q': widget.q, 'status': _statut, 'tri': 'number'}),
          element: (context, a) => TuileAppartement(a: a, onRetour: () => widget.cle.currentState?.recharger()),
        ),
      ),
    ]);
  }
}

class TuileAppartement extends StatelessWidget {
  const TuileAppartement({super.key, required this.a, this.onRetour});
  final Map<String, dynamic> a;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final locataire = a['current_tenant'] as Map?;
    return ListTile(
      title: Text('Appartement ${a['number']} · ${refs.libelle('type_appartement', a['type'] as String?)}'),
      subtitle: Text([
        (a['building'] as Map?)?['name'],
        locataire == null ? null : nomComplet(locataire),
        montant(a['rent_amount'] as num?),
      ].whereType<String>().join(' · ')),
      trailing: Statut(FamilleStatut.appartement, 'statut_appartement', a['status'] as String?),
      onTap: () async {
        await ouvrir(context, AppartementDetail(id: '${a['id']}'));
        onRetour?.call();
      },
    );
  }
}

class _ListeBaux extends StatefulWidget {
  const _ListeBaux({required this.cle});
  final GlobalKey<ListePagineeState> cle;

  @override
  State<_ListeBaux> createState() => _ListeBauxState();
}

class _ListeBauxState extends State<_ListeBaux> {
  String _statut = 'actif';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Filtres(
        options: [('', 'Tous'), for (final o in refs.options('statut_bail')) (o.code, o.label)],
        valeur: _statut,
        onChange: (v) => setState(() => _statut = v),
      ),
      Expanded(
        child: ListePaginee(
          key: widget.cle,
          cle: _statut,
          vide: 'Aucun bail',
          iconeVide: Icons.description_outlined,
          charger: (page) => api.get('/baux', query: {'page': page, 'status': _statut, 'tri': '-start_date'}),
          element: (context, b) => TuileBail(b: b, onRetour: () => widget.cle.currentState?.recharger()),
        ),
      ),
    ]);
  }
}

class TuileBail extends StatelessWidget {
  const TuileBail({super.key, required this.b, this.onRetour});
  final Map<String, dynamic> b;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final app = b['apartment'] as Map?;
    return ListTile(
      title: Text('${nomComplet(b['tenant'] as Map?)} · ${app?['number'] ?? ''}'),
      subtitle: Text('${b['reference']} · depuis le ${date(b['start_date'] as String?)} · ${montant(b['rent_amount'] as num?)}'),
      trailing: Statut(FamilleStatut.bail, 'statut_bail', b['status'] as String?),
      onTap: () async {
        await ouvrir(context, BailDetail(id: '${b['id']}'));
        onRetour?.call();
      },
    );
  }
}
