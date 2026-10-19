import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'base.dart';

/// Charge une donnée, affiche erreur / chargement, permet de tirer pour rafraîchir.
class Chargeur<T> extends StatefulWidget {
  const Chargeur({super.key, required this.charger, required this.builder, this.cle, this.page = false, this.titre});

  final Future<T> Function() charger;
  final Widget Function(BuildContext context, T data, Future<void> Function() recharger) builder;

  /// Changer la clé relance le chargement (filtres).
  final Object? cle;

  /// Écran complet : [builder] renvoie son propre Scaffold ; pendant le
  /// chargement et en cas d'erreur, une page avec barre de titre est affichée.
  final bool page;
  final String? titre;

  @override
  State<Chargeur<T>> createState() => ChargeurState<T>();
}

class ChargeurState<T> extends State<Chargeur<T>> {
  late Future<T> _futur;

  @override
  void initState() {
    super.initState();
    _futur = widget.charger();
  }

  @override
  void didUpdateWidget(covariant Chargeur<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cle != widget.cle) _futur = widget.charger();
  }

  Future<void> recharger() async {
    final f = widget.charger();
    setState(() => _futur = f);
    try {
      await f;
    } catch (_) {
      // L'erreur s'affiche dans la vue
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futur,
      builder: (context, s) {
        Widget enveloppe(Widget corps) =>
            widget.page ? Scaffold(appBar: AppBar(title: widget.titre == null ? null : Text(widget.titre!)), body: corps) : corps;
        if (s.hasError) {
          return enveloppe(ListView(children: [VueErreur(s.error!, onReessayer: recharger)]));
        }
        if (!s.hasData) return enveloppe(const Center(child: CircularProgressIndicator()));
        if (widget.page) return widget.builder(context, s.data as T, recharger);
        return RefreshIndicator(onRefresh: recharger, child: widget.builder(context, s.data as T, recharger));
      },
    );
  }
}

/// Page d'une liste paginée de l'API : `{ items, pagination }` (contrat § 0).
typedef ChargeurPage = Future<Map<String, dynamic>> Function(int page);

/// Liste à chargement progressif (cahier des charges § 37) avec tirer-pour-rafraîchir.
class ListePaginee extends StatefulWidget {
  const ListePaginee({
    super.key,
    required this.charger,
    required this.element,
    this.vide = 'Aucun élément',
    this.entete,
    this.cle,
    this.separateur = true,
    this.iconeVide = Icons.inbox_outlined,
  });

  final ChargeurPage charger;
  final Widget Function(BuildContext context, Map<String, dynamic> item) element;
  final String vide;
  final IconData iconeVide;
  final Widget? entete;

  /// Changer la clé relance depuis la première page (filtres).
  final Object? cle;
  final bool separateur;

  @override
  State<ListePaginee> createState() => ListePagineeState();
}

class ListePagineeState extends State<ListePaginee> {
  final _items = <Map<String, dynamic>>[];
  int _page = 0;
  int _pages = 1;
  bool _charge = false;
  Object? _erreur;
  final _defilement = ScrollController();

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      if (_defilement.position.pixels > _defilement.position.maxScrollExtent - 300) _suivante();
    });
    recharger();
  }

  @override
  void didUpdateWidget(covariant ListePaginee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cle != widget.cle) recharger();
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  Future<void> recharger() async {
    setState(() {
      _items.clear();
      _page = 0;
      _pages = 1;
      _erreur = null;
    });
    await _suivante();
  }

  Future<void> _suivante() async {
    if (_charge || _page >= _pages) return;
    setState(() => _charge = true);
    try {
      final r = await widget.charger(_page + 1);
      final p = r['pagination'] as Map? ?? {};
      if (!mounted) return;
      setState(() {
        _items.addAll((r['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
        _page = (p['page'] as num?)?.toInt() ?? _page + 1;
        _pages = (p['totalPages'] as num?)?.toInt() ?? _page;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enTete = widget.entete == null ? 0 : 1;
    return RefreshIndicator(
      onRefresh: recharger,
      child: ListView.separated(
        controller: _defilement,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: enTete + (_items.isEmpty ? 1 : _items.length + 1),
        separatorBuilder: (context, i) =>
            widget.separateur && i >= enTete && i < enTete + _items.length - 1 ? const Divider(height: 1, indent: 16) : const SizedBox.shrink(),
        itemBuilder: (context, i) {
          if (i < enTete) return widget.entete!;
          final k = i - enTete;
          if (_items.isEmpty) {
            if (_erreur != null) return VueErreur(_erreur!, onReessayer: recharger);
            if (_charge) return const Padding(padding: EdgeInsets.all(AppTheme.espaceXxl), child: Center(child: CircularProgressIndicator()));
            return Vide(widget.vide, icone: widget.iconeVide);
          }
          if (k == _items.length) {
            if (_erreur != null) return TextButton(onPressed: _suivante, child: const Text('Réessayer'));
            return _page < _pages
                ? const Padding(padding: EdgeInsets.all(AppTheme.espaceLg), child: Center(child: CircularProgressIndicator()))
                : const SizedBox(height: AppTheme.espaceLg);
          }
          return widget.element(context, _items[k]);
        },
      ),
    );
  }
}

/// Liste horizontale de filtres (puces) : une seule valeur active.
class Filtres extends StatelessWidget {
  const Filtres({super.key, required this.options, required this.valeur, required this.onChange});
  final List<(String, String)> options;
  final String valeur;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.espaceLg, vertical: AppTheme.espaceSm),
        children: [
          for (final (code, libelle) in options)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.espaceSm),
              child: ChoiceChip(label: Text(libelle), selected: valeur == code, onSelected: (_) => onChange(code)),
            ),
        ],
      ),
    );
  }
}
