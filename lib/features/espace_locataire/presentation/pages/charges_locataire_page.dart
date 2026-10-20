import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_charges.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/payer_en_ligne.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';

/// Mes charges (§ 28) : quote-part des factures communes, payable comme un loyer.
class ChargesLocatairePage extends StatelessWidget {
  const ChargesLocatairePage({super.key});

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
                  onTap: () => Navigator.pop(ctx, o.code)),
          ],
        ),
      ),
    );
    if (choix == null || !context.mounted) return;
    final d = await executer(
        context, () => sl<PayerEnLigne>()(chargeId: c.id, portefeuille: choix));
    if (d?.checkoutUrl != null && context.mounted) {
      await ouvrirPaiement(context, d!.transactionId, d.checkoutUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes charges')),
      body: ListePaginee<ChargeRefacturee>(
        vide: 'Aucune charge',
        iconeVide: Icons.water_drop_outlined,
        charger: (page) => sl<GetMesCharges>()(page: page),
        element: (context, c) => ListTile(
          title: Text(c.libelle ?? ''),
          subtitle: Text(
              '${refs.libelle('type_charge', c.typeCharge)} · échéance ${date(c.dateEcheance)}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Montant(c.payable ? c.reste : c.montant,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Statut(FamilleStatut.charge, 'statut_charge', c.statut),
            ],
          ),
          onTap: c.payable ? () => _payer(context, c) : null,
        ),
      ),
    );
  }
}
