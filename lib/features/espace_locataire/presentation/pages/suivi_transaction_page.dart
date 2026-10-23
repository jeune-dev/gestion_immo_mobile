import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/widgets/actions.dart';

import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/suivi_transaction_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/suivi_transaction_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/suivi_transaction_state.dart';

/// Suivi d'un paiement en ligne : la confirmation vient du serveur (webhook PayDunya).
class SuiviTransactionPage extends StatefulWidget {
  final String id;
  final String? checkoutUrl;
  const SuiviTransactionPage({super.key, required this.id, this.checkoutUrl});

  @override
  State<SuiviTransactionPage> createState() => _SuiviTransactionPageState();
}

class _SuiviTransactionPageState extends State<SuiviTransactionPage>
    with WidgetsBindingObserver {
  late final _bloc = di.sl<SuiviTransactionBloc>()
    ..add(DemarrerSuiviTransaction(widget.id));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Retour depuis l'application Wave / Orange Money : vérification immédiate.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) {
      _bloc.add(VerifierTransactionEvent(widget.id));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuiviTransactionBloc, SuiviTransactionState>(
      bloc: _bloc,
      builder: (context, state) {
        final t = state is SuiviTransactionLoaded ? state.transaction : null;
        final statut = t?.statut;
        final (icone, titre, texte, ton) = switch (statut) {
          'confirmee' => (
              Icons.check_circle_outline,
              'Paiement confirmé',
              'Merci ! Votre quittance est disponible dans « Mes quittances ».',
              TonStatut.succes,
            ),
          'echouee' || 'annulee' => (
              Icons.error_outline,
              'Paiement non abouti',
              'Aucun montant n’a été débité. Vous pouvez réessayer.',
              TonStatut.danger
            ),
          'a_rapprocher' => (
              Icons.schedule,
              'Paiement reçu',
              'Votre propriétaire doit l’associer à votre échéance.',
              TonStatut.avertissement
            ),
          _ => (
              Icons.hourglass_top,
              'En attente de confirmation',
              'Validez le paiement dans votre application Wave / Orange Money, puis revenez ici.',
              TonStatut.info,
            ),
        };
        final c = couleursDuTon(context, ton);
        return Scaffold(
          appBar: AppBar(title: const Text('Suivi du paiement')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(icone, size: 72, color: c.texte),
              const SizedBox(height: 16),
              Text(titre,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(texte, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (t != null)
                Section(
                  children: [
                    Ligne('Montant', montant(t.montant)),
                    Ligne('Référence', t.reference ?? ''),
                    Ligne('Statut', null,
                        widget: Statut(FamilleStatut.transaction,
                            'statut_transaction', statut)),
                  ],
                ),
              const SizedBox(height: 24),
              if (!(t?.termine ?? false) && widget.checkoutUrl != null)
                OutlinedButton(
                  onPressed: () => ouvrirLien(context, widget.checkoutUrl!,
                      mode: LaunchMode.externalApplication),
                  child: const Text('Rouvrir la page de paiement'),
                ),
              TextButton(
                onPressed: () => _bloc.add(VerifierTransactionEvent(widget.id)),
                child: const Text('Vérifier maintenant'),
              ),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Terminer')),
            ],
          ),
        );
      },
    );
  }
}

/// Ouvre la page de paiement puis l'écran de suivi.
Future<void> ouvrirPaiement(
    BuildContext context, String transactionId, String checkoutUrl) async {
  await ouvrirLien(context, checkoutUrl,
      mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          SuiviTransactionPage(id: transactionId, checkoutUrl: checkoutUrl),
    ),
  );
}
