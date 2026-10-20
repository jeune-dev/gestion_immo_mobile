import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/get_factures_a_repartir.dart';

/// Factures en brouillon à répartir : bandeau au-dessus de la liste, qui filtre
/// sur les brouillons d'un toucher. [cle] change pour le relire.
class BandeauARepartir extends StatelessWidget {
  final Object cle;
  final VoidCallback onVoir;
  const BandeauARepartir({super.key, required this.cle, required this.onVoir});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, FacturesARepartir>>(
      key: ValueKey(cle),
      future: sl<GetFacturesARepartir>()(),
      builder: (context, s) {
        final a = s.data?.fold((_) => null, (a) => a);
        if (a == null || a.nombre == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Encadre(
            '${a.nombre} facture${a.nombre > 1 ? 's' : ''} à répartir · ${montant(a.total)}',
            ton: TonStatut.avertissement,
            action: TextButton(onPressed: onVoir, child: const Text('Voir')),
          ),
        );
      },
    );
  }
}
