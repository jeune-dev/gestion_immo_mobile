import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
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
class QuittanceDetailPage extends StatefulWidget {
  final String id;
  final bool espaceLocataire;
  const QuittanceDetailPage({
    super.key,
    required this.id,
    this.espaceLocataire = false,
  });

  @override
  State<QuittanceDetailPage> createState() => _QuittanceDetailPageState();
}

class _QuittanceDetailPageState extends State<QuittanceDetailPage> {
  late Future<Either<Failure, Quittance>> _fiche = _charger();

  Future<Either<Failure, Quittance>> _charger() =>
      sl<GetQuittance>()(widget.id, espaceLocataire: widget.espaceLocataire);

  void _recharger() => setState(() => _fiche = _charger());

  void _pdf(Quittance q, {bool partager = false}) => ouvrirPdf(
    context,
    () => sl<TelechargerQuittance>()(
      q.id,
      espaceLocataire: widget.espaceLocataire,
    ),
    'quittance-${q.numero ?? q.id}.pdf',
    partager: partager,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, Quittance>>(
      future: _fiche,
      builder: (context, s) {
        if (!s.hasData) return const VueChargement(titre: 'Quittance');
        return s.data!.fold(
          (f) => VueChargement(
            titre: 'Quittance',
            failure: f,
            onReessayer: _recharger,
          ),
          (q) => _buildFiche(context, q),
        );
      },
    );
  }

  Widget _buildFiche(BuildContext context, Quittance q) {
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
        onRefresh: () async => _recharger(),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          children: [
            CarteMarque(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (q.libelleEcheance ?? 'Quittance de loyer')
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (q.annulee)
                        const Pastille('Annulée', ton: TonStatut.neutre),
                    ],
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  Text(
                    montant(q.montant),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.espaceXs),
                  Text(
                    'Émise le ${date(q.emiseLe)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Détail',
              children: [
                if (q.numero != null) Ligne('Numéro', q.numero),
                if (!widget.espaceLocataire && q.locataire != null)
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
                onPressed: () => _pdf(q),
              ),
              const SizedBox(height: AppTheme.espaceSm),
              OutlinedButton.icon(
                icon: const Icon(Icons.ios_share),
                label: const Text('Partager'),
                onPressed: () => _pdf(q, partager: true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
