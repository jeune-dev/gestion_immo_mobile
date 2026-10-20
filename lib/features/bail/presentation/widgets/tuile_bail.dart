import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/pages/bail_detail_page.dart';

class TuileBail extends StatelessWidget {
  final Bail b;
  final VoidCallback? onRetour;
  const TuileBail({super.key, required this.b, this.onRetour});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${nomDe(b.locataire)} · ${b.logement?.numero ?? ''}'),
      subtitle: Text(
          '${b.reference ?? ''} · depuis le ${date(b.debut)} · ${montant(b.loyer)}'),
      trailing: Statut(FamilleStatut.bail, 'statut_bail', b.statut),
      onTap: () async {
        await ouvrir(context, BailDetailPage(id: b.id));
        onRetour?.call();
      },
    );
  }
}
