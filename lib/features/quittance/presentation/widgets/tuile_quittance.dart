import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
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
  const TuileQuittance({
    super.key,
    required this.q,
    this.espaceLocataire = false,
  });

  void _pdf(BuildContext context, {bool partager = false}) => ouvrirPdf(
    context,
    () => sl<TelechargerQuittance>()(q.id, espaceLocataire: espaceLocataire),
    'quittance-${q.numero}.pdf',
    partager: partager,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sousTitre = [
      if (!espaceLocataire) nomDe(q.locataire),
      if (q.numero != null) 'N° ${q.numero}',
      'Émise le ${date(q.emiseLe)}',
    ].join(' · ');
    return InkWell(
      onTap: () => _pdf(context),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.espaceMd),
        child: Row(
          children: [
            const IconeOption(Icons.picture_as_pdf_outlined),
            const SizedBox(width: AppTheme.espaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.libelleEcheance ?? 'Quittance',
                    style: TextStyle(
                      color: p.texte,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sousTitre,
                    style: TextStyle(color: p.texteSecondaire, fontSize: 12.5),
                  ),
                  const SizedBox(height: AppTheme.espaceXs),
                  Montant(
                    q.montant,
                    style: TextStyle(
                      color: p.texte,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (q.annulee)
              const Pastille('Annulée', ton: TonStatut.neutre)
            else
              IconButton(
                tooltip: 'Partager',
                icon: const Icon(Icons.ios_share),
                onPressed: () => _pdf(context, partager: true),
              ),
          ],
        ),
      ),
    );
  }
}
