import 'package:flutter/material.dart';

/// Ouvre un écran ; renvoie son résultat.
Future<T?> ouvrir<T>(BuildContext context, Widget ecran) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => ecran));

/// Menu d'actions (⋮) d'un écran de détail.
class MenuActions extends StatelessWidget {
  const MenuActions({super.key, required this.actions});

  /// (libellé, action, danger)
  final List<(String, VoidCallback, bool)> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      tooltip: 'Actions',
      onSelected: (i) => actions[i].$2(),
      itemBuilder: (_) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem(value: i, child: Text(actions[i].$1, style: actions[i].$3 ? TextStyle(color: cs.error) : null)),
      ],
    );
  }
}
