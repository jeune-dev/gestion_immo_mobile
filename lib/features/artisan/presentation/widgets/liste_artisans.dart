import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/entities/artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/usecases/get_artisans.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/pages/artisan_detail_page.dart';

class ListeArtisans extends StatelessWidget {
  final GlobalKey<ListePagineeState<Artisan>> cle;
  const ListeArtisans({super.key, required this.cle});

  @override
  Widget build(BuildContext context) {
    return ListePaginee<Artisan>(
      key: cle,
      vide: 'Aucun artisan',
      iconeVide: Icons.engineering_outlined,
      charger: (page) => sl<GetArtisans>()(page: page),
      element: (context, a) => ListTile(
        leading: CircleAvatar(
            child: Icon(a.actif ? Icons.engineering_outlined : Icons.block,
                size: 20)),
        title: Text(a.nom),
        subtitle: Text(
            '${refs.libelle('metier_artisan', a.metier)} · ${a.interventions} intervention(s) · ${montant(a.totalPaye)}'),
        trailing: a.actif
            ? const Icon(Icons.chevron_right)
            : const Pastille('Inactif'),
        onTap: () async {
          await ouvrirArtisan(context, a.id);
          cle.currentState?.recharger();
        },
      ),
    );
  }
}
