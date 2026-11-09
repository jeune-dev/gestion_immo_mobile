import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/entities/quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/usecases/get_quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/usecases/telecharger_quittance.dart';

/// Fiche d'une quittance (§ 13) : échéance réglée, période, logement, PDF.
class QuittanceDetailPage extends StatelessWidget {
  final String id;
  final bool espaceLocataire;
  const QuittanceDetailPage({
    super.key,
    required this.id,
    this.espaceLocataire = false,
  });

  void _pdf(BuildContext context, Quittance q, {bool partager = false}) =>
      ouvrirPdf(
        context,
        () =>
            sl<TelechargerQuittance>()(q.id, espaceLocataire: espaceLocataire),
        'quittance-${q.numero ?? q.id}.pdf',
        partager: partager,
      );

  @override
  Widget build(BuildContext context) => FicheChargee<Quittance>(
    titre: 'Quittance',
    charger: () => sl<GetQuittance>()(id, espaceLocataire: espaceLocataire),
    fiche: (context, q, recharger) {
      final logement = [
        if (q.immeuble != null) q.immeuble!,
        if (q.logementNumero != null) 'Appartement ${q.logementNumero}',
      ].join(' · ');
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: const FondMarque(),
          title: Text(q.numero == null ? 'Quittance' : 'N° ${q.numero}'),
        ),
        body: RefreshIndicator(
          onRefresh: () async => recharger(),
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.espaceMd),
            children: [
              CarteMontant(
                surtitre: q.libelleEcheance ?? 'Quittance de loyer',
                statut: q.annulee
                    ? const Pastille('Annulée', ton: TonStatut.neutre)
                    : null,
                montant: q.montant,
                sousTitre: 'Émise le ${date(q.emiseLe)}',
              ),
              const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: 'Détail',
                children: [
                  if (q.numero != null) Ligne('Numéro', q.numero),
                  if (!espaceLocataire && q.locataire != null)
                    Ligne('Locataire', nomDe(q.locataire)),
                  if (logement.isNotEmpty) Ligne('Logement', logement),
                  if (q.periodeDebut != null || q.periodeFin != null)
                    Ligne(
                      'Période',
                      '${date(q.periodeDebut)} → ${date(q.periodeFin)}',
                    ),
                  Ligne('Montant', montant(q.montant)),
                  if (q.referencesPaiement.isNotEmpty)
                    Ligne('Paiements', q.referencesPaiement.join(', ')),
                ],
              ),
              if (!q.annulee) ...[
                const SizedBox(height: AppTheme.espaceLg),
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Voir le PDF'),
                  onPressed: () => _pdf(context, q),
                ),
                const SizedBox(height: AppTheme.espaceSm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Partager'),
                  onPressed: () => _pdf(context, q, partager: true),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
