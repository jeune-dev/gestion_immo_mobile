import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/pages/appartement_detail_page.dart';

class TuileAppartement extends StatelessWidget {
  final Appartement a;
  final VoidCallback? onRetour;
  const TuileAppartement({super.key, required this.a, this.onRetour});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
          'Appartement ${a.numero} · ${refs.libelle('type_appartement', a.type)}'),
      subtitle: Text([
        a.immeubleNom,
        a.locataireCourant?.nomComplet,
        montant(a.loyer)
      ].whereType<String>().join(' · ')),
      trailing:
          Statut(FamilleStatut.appartement, 'statut_appartement', a.statut),
      onTap: () async {
        await ouvrir(context, AppartementDetailPage(id: a.id));
        onRetour?.call();
      },
    );
  }
}
