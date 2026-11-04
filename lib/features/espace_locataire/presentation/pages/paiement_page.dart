import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/declarer_preuve_paiement.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_state.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/widgets/choix_paiement.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/messagerie_page.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Paiement d'une échéance par le locataire (§ 12, § 51). Jamais hors ligne :
/// toute confirmation vient du serveur. Renvoie `true` si un paiement a été initié.
Future<bool?> payer(
  BuildContext context, {
  required Echeance echeance,
  required String bailId,
}) {
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
        titre: 'Paiement ${refs.libelle('portefeuille', moyen.portefeuille)}',
        initial: {'amount': echeance.reste},
        intro: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EtapesPaiement(etape: 2),
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Envoyez le paiement',
              children: [
                _LigneACopier('Numéro', moyen.numero ?? ''),
                _LigneACopier('Montant', montant(echeance.reste)),
                if (moyen.libelle != null) Ligne('Au nom de', moyen.libelle),
              ],
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Text(
              'Puis déclarez-le : votre propriétaire le validera.',
              style: TextStyle(color: context.palette.texteSecondaire),
            ),
            const SizedBox(height: AppTheme.espaceMd),
            StatefulBuilder(
              builder: (ctx, setState) => OutlinedButton.icon(
                onPressed: () async {
                  final p = await choisirPhoto(ctx);
                  if (p != null && ctx.mounted) setState(() => photo = p.path);
                },
                icon: Icon(
                  photo == null ? Icons.add_a_photo_outlined : Icons.check,
                ),
                label: Text(
                  photo == null
                      ? 'Joindre la capture du reçu (facultatif)'
                      : 'Capture jointe',
                ),
              ),
            ),
          ],
        ),
        champs: const [
          Champ(
            'provider_transaction_id',
            'Numéro de transaction',
            obligatoire: true,
            minLongueur: 4,
            maxLongueur: 100,
            indice: 'Reçu par SMS après votre envoi',
            icone: Icons.tag,
            format: (
              r'^[A-Za-z0-9_\-./]+$',
              'Lettres, chiffres et . _ - / uniquement, sans espace',
            ),
          ),
          Champ(
            'amount',
            'Montant envoyé',
            type: TypeChamp.montant,
            obligatoire: true,
            min: 1,
          ),
          Champ(
            'payer_phone',
            'Numéro qui a payé',
            type: TypeChamp.telephone,
            icone: Icons.phone_outlined,
          ),
        ],
        libelleEnvoi: 'Déclarer le paiement',
        messageSucces: 'Paiement déclaré : votre propriétaire va le vérifier.',
        envoyer: (c) async {
          (await di.sl<DeclarerPreuvePaiement>()({
            ...c,
            'rent_schedule_id': echeance.id,
            'wallet': moyen.portefeuille,
          }, capture: photo)).ouLeve();
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
            return _buildFiche(
              context,
              state.moyens,
              paiementEnCours: state.paiementEnCours,
            );
          }
          return VueChargement(
            titre: 'Payer',
            failure: state is PaiementLocataireError ? state.failure : null,
            onReessayer: () => context.read<PaiementLocataireBloc>().add(
              LoadPaiementLocataire(bailId),
            ),
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
      await ouvrirLien(context, url, mode: LaunchMode.externalApplication);
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

  Widget _buildFiche(
    BuildContext context,
    MoyensPaiementLocataire m, {
    bool paiementEnCours = false,
  }) {
    final bloc = context.read<PaiementLocataireBloc>();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Payer mon loyer'),
      ),
      body: ChoixPaiement(
        echeance: echeance,
        moyens: m,
        enCours: paiementEnCours,
        onPayerEnLigne: (w) =>
            bloc.add(PayerEnLigneEvent(bailId, echeance.id, echeance.reste, w)),
        onDeclarer: (p) => _preuve(context, p),
        onContacter: () =>
            ouvrir(context, const MessageriePage(espaceLocataire: true)),
      ),
    );
  }
}

/// Ligne d'instruction avec un bouton pour copier la valeur.
class _LigneACopier extends StatelessWidget {
  final String libelle;
  final String valeur;
  const _LigneACopier(this.libelle, this.valeur);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Ligne(libelle, valeur)),
      IconButton(
        tooltip: 'Copier',
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: valeur));
          if (context.mounted) afficherSucces(context, '$libelle copié');
        },
      ),
    ],
  );
}
