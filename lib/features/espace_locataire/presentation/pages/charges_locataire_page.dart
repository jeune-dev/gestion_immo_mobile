import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_ma_charge.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_charges.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/payer_en_ligne.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Paiement en ligne d'une charge : choix du portefeuille, puis page du fournisseur.
Future<void> _payer(BuildContext context, ChargeRefacturee c) async {
  final choix = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Payer ${montant(c.reste)}')),
          for (final o in refs.options('portefeuille'))
            ListTile(
              leading: const Icon(Icons.phone_iphone),
              title: Text('Avec ${o.label}'),
              onTap: () => Navigator.pop(ctx, o.code),
            ),
        ],
      ),
    ),
  );
  if (choix == null || !context.mounted) return;
  final d = await executer(
    context,
    () => sl<PayerEnLigne>()(chargeId: c.id, portefeuille: choix),
  );
  if (d?.checkoutUrl != null && context.mounted) {
    await ouvrirPaiement(context, d!.transactionId, d.checkoutUrl!);
  }
}

/// Mes charges (§ 28) : quote-part des factures communes, payable comme un loyer.
class ChargesLocatairePage extends StatefulWidget {
  const ChargesLocatairePage({super.key});

  @override
  State<ChargesLocatairePage> createState() => _ChargesLocatairePageState();
}

class _ChargesLocatairePageState extends State<ChargesLocatairePage> {
  final _liste = GlobalKey<ListePagineeState<ChargeRefacturee>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Mes charges'),
      ),
      body: ListePaginee<ChargeRefacturee>(
        key: _liste,
        vide: 'Aucune charge',
        iconeVide: Icons.water_drop_outlined,
        charger: (page) => sl<GetMesCharges>()(page: page),
        element: (context, c) => TuileOption(
          icone: Icons.water_drop_outlined,
          titre: c.libelle ?? 'Charge',
          detail:
              '${refs.libelle('type_charge', c.typeCharge)} · échéance ${date(c.dateEcheance)}',
          fin: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Montant(
                c.payable ? c.reste : c.montant,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.espaceXs),
              Statut(FamilleStatut.charge, 'statut_charge', c.statut),
            ],
          ),
          onTap: () async {
            await ouvrir(context, ChargeLocataireDetailPage(id: c.id));
            _liste.currentState?.recharger();
          },
        ),
      ),
    );
  }
}

/// Détail d'une charge : montant, statut et explication du calcul de SA part.
class ChargeLocataireDetailPage extends StatefulWidget {
  final String id;
  const ChargeLocataireDetailPage({super.key, required this.id});

  @override
  State<ChargeLocataireDetailPage> createState() =>
      _ChargeLocataireDetailPageState();
}

class _ChargeLocataireDetailPageState extends State<ChargeLocataireDetailPage> {
  late Future<Either<Failure, ChargeRefacturee>> _charge = _charger();

  Future<Either<Failure, ChargeRefacturee>> _charger() =>
      sl<GetMaCharge>()(widget.id);

  void _recharger() => setState(() => _charge = _charger());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, ChargeRefacturee>>(
      future: _charge,
      builder: (context, s) {
        if (!s.hasData) return const VueChargement(titre: 'Charge');
        return s.data!.fold(
          (f) => VueChargement(
            titre: 'Charge',
            failure: f,
            onReessayer: _recharger,
          ),
          (c) => _buildFiche(context, c),
        );
      },
    );
  }

  Widget _buildFiche(BuildContext context, ChargeRefacturee c) {
    final k = c.calcul;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(c.libelle ?? 'Charge'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CarteMarque(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          refs
                              .libelle('type_charge', c.typeCharge)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Statut(FamilleStatut.charge, 'statut_charge', c.statut),
                    ],
                  ),
                  const SizedBox(height: AppTheme.espaceSm),
                  Text(
                    montant(c.payable ? c.reste : c.montant),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.espaceXs),
                  Text(
                    c.payable
                        ? 'Reste à payer · échéance ${date(c.dateEcheance)}'
                        : 'Échéance ${date(c.dateEcheance)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Détail',
              children: [
                Ligne('Montant total', montant(c.montant)),
                Ligne('Déjà payé', montant(c.montantPaye)),
              ],
            ),
            if (k != null) ...[
              const SizedBox(height: 16),
              Section(
                titre: 'Calcul de votre part',
                children: [
                  Ligne('Facture', k.fournisseur),
                  if (k.numeroFacture != null)
                    Ligne('N° de facture', k.numeroFacture),
                  if (k.periodeDebut != null || k.periodeFin != null)
                    Ligne(
                      'Période',
                      '${date(k.periodeDebut)} → ${date(k.periodeFin)}',
                    ),
                  Ligne('Total de la facture', montant(k.totalFacture)),
                  Ligne('Logements concernés', '${k.nbAppartements}'),
                  Ligne('Méthode', k.methodeLibelle ?? k.methode),
                  Ligne('Votre part', montant(c.montant)),
                ],
              ),
              if (k.explication != null && k.explication!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Encadre(k.explication!),
              ],
            ],
            if (c.payable) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.payments_outlined),
                label: Text('Payer ${montant(c.reste)}'),
                onPressed: () async {
                  await _payer(context, c);
                  if (mounted) _recharger();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
