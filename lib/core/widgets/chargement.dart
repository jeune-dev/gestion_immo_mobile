import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/bloc/actions_cubit.dart';
import 'package:gestion_immo_mobile/core/bloc/pagination_cubit.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'actions.dart';
import 'base.dart';

export 'package:gestion_immo_mobile/core/bloc/actions_cubit.dart';
export 'package:gestion_immo_mobile/core/bloc/pagination_cubit.dart'
    show ChargeurPage;

/// Liste paginée de l'API (cahier des charges § 37) branchée sur un
/// [PaginationCubit] : chargement progressif au défilement, tirer-pour-rafraîchir.
class ListePaginee<T> extends StatefulWidget {
  /// Cas d'usage qui renvoie la page demandée.
  final ChargeurPage<T> charger;

  final Widget Function(BuildContext context, T item) element;
  final String vide;
  final IconData iconeVide;
  final Widget? entete;

  /// Changer la clé relance depuis la première page (filtres).
  final Object? cle;
  final bool separateur;

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

  @override
  State<ListePaginee<T>> createState() => ListePagineeState<T>();
}

class ListePagineeState<T> extends State<ListePaginee<T>> {
  late final PaginationCubit<T> _cubit = PaginationCubit<T>(widget.charger)
    ..recharger();
  final _defilement = ScrollController();

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      if (_defilement.position.pixels >
          _defilement.position.maxScrollExtent - 300) {
        _cubit.suivante();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ListePaginee<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cle != widget.cle) _cubit.changerSource(widget.charger);
  }

  @override
  void dispose() {
    _defilement.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> recharger() => _cubit.changerSource(widget.charger);

  @override
  Widget build(BuildContext context) {
    final enTete = widget.entete == null ? 0 : 1;
    return BlocBuilder<PaginationCubit<T>, PaginationState<T>>(
      bloc: _cubit,
      builder: (context, s) => RefreshIndicator(
        onRefresh: recharger,
        child: ListView.separated(
          controller: _defilement,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: enTete + (s.items.isEmpty ? 1 : s.items.length + 1),
          separatorBuilder: (context, i) => widget.separateur &&
                  i >= enTete &&
                  i < enTete + s.items.length - 1
              ? const Divider(height: 1, indent: 16)
              : const SizedBox.shrink(),
          itemBuilder: (context, i) {
            if (i < enTete) return widget.entete!;
            final k = i - enTete;
            if (s.items.isEmpty) {
              if (s.failure != null) {
                return VueErreur(s.failure!, onReessayer: recharger);
              }
              if (s.enCours) {
                return const Padding(
                  padding: EdgeInsets.all(AppTheme.espaceXxl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Vide(widget.vide, icone: widget.iconeVide);
            }
            if (k == s.items.length) {
              if (s.failure != null) {
                return TextButton(
                    onPressed: _cubit.suivante, child: const Text('Réessayer'));
              }
              return s.aSuite
                  ? const Padding(
                      padding: EdgeInsets.all(AppTheme.espaceLg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox(height: AppTheme.espaceLg);
            }
            return widget.element(context, s.items[k]);
          },
        ),
      ),
    );
  }
}

/// Contenu d'un écran chargé par un Bloc : chargement, erreur avec « Réessayer », ou données.
class VueChargement extends StatelessWidget {
  final Object? failure;
  final VoidCallback? onReessayer;

  /// Avec un titre, la vue est une page complète (barre de titre comprise).
  final String? titre;

  const VueChargement({super.key, this.failure, this.onReessayer, this.titre});

  @override
  Widget build(BuildContext context) {
    final corps = failure != null
        ? ListView(
            children: [VueErreur(failure!, onReessayer: onReessayer ?? () {})])
        : const Center(child: CircularProgressIndicator());
    return titre == null
        ? corps
        : Scaffold(
            appBar: AppBar(title: Text(titre!)),
            body: corps,
          );
  }
}

/// Liste horizontale de filtres (puces) : une seule valeur active.
class Filtres extends StatelessWidget {
  final List<(String, String)> options;
  final String valeur;
  final ValueChanged<String> onChange;
  const Filtres(
      {super.key,
      required this.options,
      required this.valeur,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.espaceLg, vertical: AppTheme.espaceSm),
        children: [
          for (final (code, libelle) in options)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.espaceSm),
              child: ChoiceChip(
                  label: Text(libelle),
                  selected: valeur == code,
                  onSelected: (_) => onChange(code)),
            ),
        ],
      ),
    );
  }
}

/// Fournit un [ActionsCubit] à un écran de liste et affiche ses messages ;
/// [onReussite] recharge la liste après une action réussie.
class AvecActions extends StatelessWidget {
  final Widget child;
  final VoidCallback? onReussite;
  const AvecActions({super.key, required this.child, this.onReussite});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActionsCubit(),
      child: BlocListener<ActionsCubit, EtatActions>(
        listenWhen: (a, b) => a.version != b.version,
        listener: (context, s) {
          if (s.failure != null) return afficherErreurApi(context, s.failure!);
          if (s.succes != null) afficherSucces(context, s.succes!);
          onReussite?.call();
        },
        child: child,
      ),
    );
  }
}
