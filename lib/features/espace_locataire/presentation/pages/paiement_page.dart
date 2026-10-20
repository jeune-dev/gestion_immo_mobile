import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/declarer_preuve_paiement.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_state.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';

/// Paiement d'une échéance par le locataire (§ 12, § 51). Jamais hors ligne :
/// toute confirmation vient du serveur. Renvoie `true` si un paiement a été initié.
Future<bool?> payer(BuildContext context,
    {required Echeance echeance, required String bailId}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaiementPage(echeance: echeance, bailId: bailId),
    ),
  );
}

class PaiementPage extends StatelessWidget {
  final Echeance echeance;
  final String bailId;
  const PaiementPage({super.key, required this.echeance, required this.bailId});

  /// Paiement direct : le locataire a payé sur le numéro du propriétaire et déclare la transaction.
  Future<void> _preuve(BuildContext context, MoyenPreuve moyen) async {
    String? photo;
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre:
            'Déclarer mon paiement ${refs.libelle('portefeuille', moyen.portefeuille)}',
        initial: {'amount': echeance.reste},
        intro: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Encadre(
              'Envoyez ${montant(echeance.reste)} au ${moyen.numero ?? ''} (${moyen.libelle ?? refs.libelle('portefeuille', moyen.portefeuille)}), '
              'puis indiquez ci-dessous le numéro de transaction reçu par SMS. Votre propriétaire validera le paiement.',
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (ctx, setState) => OutlinedButton.icon(
                onPressed: () async {
                  final p = await choisirPhoto(ctx);
                  if (p != null) setState(() => photo = p.path);
                },
                icon: Icon(
                    photo == null ? Icons.add_a_photo_outlined : Icons.check),
                label: Text(photo == null
                    ? 'Joindre la capture du reçu (facultatif)'
                    : 'Capture jointe'),
              ),
            ),
          ],
        ),
        champs: const [
          Champ('provider_transaction_id', 'Numéro de transaction',
              obligatoire: true, maxLongueur: 100),
          Champ('amount', 'Montant envoyé',
              type: TypeChamp.montant, obligatoire: true, min: 1),
          Champ('payer_phone', 'Numéro qui a payé', type: TypeChamp.telephone),
        ],
        libelleEnvoi: 'Déclarer le paiement',
        messageSucces: 'Paiement déclaré : votre propriétaire va le vérifier.',
        envoyer: (c) async {
          (await di.sl<DeclarerPreuvePaiement>()({
            ...c,
            'rent_schedule_id': echeance.id,
            'wallet': moyen.portefeuille
          }, capture: photo))
              .ouLeve();
          return true;
        },
      ),
    );
    if (r != null && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<PaiementLocataireBloc>()..add(LoadPaiementLocataire(bailId)),
      child: BlocConsumer<PaiementLocataireBloc, PaiementLocataireState>(
        listener: (context, state) {
          if (state is PaiementLocataireSuccess) {
            afficherSucces(context, state.message);
          } else if (state is PaiementLocataireActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is DemandePaiementLoaded) {
            _suivrePaiement(context, state);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is PaiementLocataireInitial ||
            state is PaiementLocataireLoading ||
            state is PaiementLocataireLoaded ||
            state is PaiementLocataireError,
        builder: (context, state) {
          if (state is PaiementLocataireLoaded) {
            return _buildFiche(context, state.moyens);
          }
          return VueChargement(
            titre: 'Payer',
            failure: state is PaiementLocataireError ? state.failure : null,
            onReessayer: () => context
                .read<PaiementLocataireBloc>()
                .add(LoadPaiementLocataire(bailId)),
          );
        },
      ),
    );
  }

  /// Paiement intégré : demande PayDunya créée, puis page Wave / Orange Money
  /// et suivi.
  Future<void> _suivrePaiement(
    BuildContext context,
    DemandePaiementLoaded state,
  ) async {
    final url = state.demande.checkoutUrl;
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SuiviTransactionPage(
          id: state.demande.transactionId,
          checkoutUrl: url,
        ),
      ),
    );
  }

  Widget _buildFiche(BuildContext context, MoyensPaiementLocataire m) {
    final bloc = context.read<PaiementLocataireBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Payer mon loyer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            children: [
              Text(echeance.libelle ?? '',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Montant(echeance.reste,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w600)),
              Text('Bénéficiaire : ${m.beneficiaire ?? ''}'),
            ],
          ),
          const SizedBox(height: AppTheme.espaceLg),
          if (m.integres.isNotEmpty) ...[
            Text('Payer maintenant',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final w in m.integres)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  onPressed: () => bloc.add(PayerEnLigneEvent(
                      bailId, echeance.id, echeance.reste, w)),
                  icon: const Icon(Icons.phone_iphone),
                  label: Text('Payer avec ${refs.libelle('portefeuille', w)}'),
                ),
              ),
            const SizedBox(height: AppTheme.espaceLg),
          ],
          if (m.preuves.isNotEmpty) ...[
            Text("J'ai déjà payé directement",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in m.preuves)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_outlined),
                  title: Text(p.libelle ??
                      refs.libelle('portefeuille', p.portefeuille)),
                  subtitle: Text('Envoyer au ${p.numero ?? ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _preuve(context, p),
                ),
              ),
            const SizedBox(height: AppTheme.espaceLg),
          ],
          if (m.especes)
            const Encadre(
              'Vous pouvez aussi payer en espèces à votre propriétaire : il enregistre le paiement et votre quittance apparaît ici.',
            ),
          if (m.integres.isEmpty && m.preuves.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Encadre(
                  'Votre propriétaire n’a pas encore activé le paiement par Wave ou Orange Money.',
                  ton: TonStatut.avertissement),
            ),
        ],
      ),
    );
  }
}
