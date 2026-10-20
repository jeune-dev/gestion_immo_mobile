import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/utils/format.dart';

/// Période (du / au) avec raccourcis : ce mois, mois dernier, cette année.
class Periode {
  final String du;
  final String au;
  const Periode(this.du, this.au);

  static Periode moisCourant() {
    final n = DateTime.now().toUtc();
    return Periode(versApi(DateTime.utc(n.year, n.month, 1)),
        versApi(DateTime.utc(n.year, n.month + 1, 0)));
  }

  static Periode moisPrecedent() {
    final n = DateTime.now().toUtc();
    return Periode(versApi(DateTime.utc(n.year, n.month - 1, 1)),
        versApi(DateTime.utc(n.year, n.month, 0)));
  }

  static Periode anneeCourante() {
    final n = DateTime.now().toUtc();
    return Periode('${n.year}-01-01', '${n.year}-12-31');
  }

  String get libelle => '${date(du)} → ${date(au)}';

  @override
  bool operator ==(Object other) =>
      other is Periode && other.du == du && other.au == au;

  @override
  int get hashCode => Object.hash(du, au);
}

class ChoixPeriode extends StatelessWidget {
  final Periode periode;
  final ValueChanged<Periode> onChange;
  const ChoixPeriode(
      {super.key, required this.periode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('Ce mois', Periode.moisCourant()),
      ('Mois dernier', Periode.moisPrecedent()),
      ('Cette année', Periode.anneeCourante())
    ];
    final perso = !options.any((o) => o.$2 == periode);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final (l, p) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: Text(l),
                  selected: periode == p,
                  onSelected: (_) => onChange(p)),
            ),
          ChoiceChip(
            label: Text(perso ? periode.libelle : 'Autre période'),
            selected: perso,
            onSelected: (_) async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: DateTimeRange(
                    start: DateTime.parse(periode.du),
                    end: DateTime.parse(periode.au)),
                locale: const Locale('fr'),
              );
              if (r != null) {
                onChange(Periode(versApi(r.start), versApi(r.end)));
              }
            },
          ),
        ],
      ),
    );
  }
}
