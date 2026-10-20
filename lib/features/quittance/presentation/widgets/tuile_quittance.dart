import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/entities/quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/usecases/telecharger_quittance.dart';

class TuileQuittance extends StatelessWidget {
  final Quittance q;
  final bool espaceLocataire;
  const TuileQuittance(
      {super.key, required this.q, this.espaceLocataire = false});

  void _pdf(BuildContext context, {bool partager = false}) => ouvrirPdf(
      context,
      () => sl<TelechargerQuittance>()(q.id, espaceLocataire: espaceLocataire),
      'quittance-${q.numero}.pdf',
      partager: partager);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: Text('${q.numero ?? ''} · ${q.libelleEcheance ?? ''}'),
      subtitle: Text('${nomDe(q.locataire)} · émise le ${date(q.emiseLe)}'),
      trailing: q.annulee
          ? const Pastille('Annulée', ton: TonStatut.neutre)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Montant(q.montant),
                IconButton(
                    tooltip: 'Partager',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _pdf(context, partager: true)),
              ],
            ),
      onTap: () => _pdf(context),
    );
  }
}
