import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/get_transactions.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/transaction_bloc.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/transaction_event.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/transaction_state.dart';

/// Paiements en ligne (Wave, Orange Money via PayDunya) et paiements directs
/// déclarés avec une preuve, que le propriétaire valide ou rejette (§ 12, § 51).
class TransactionsPage extends StatefulWidget {
  final bool aValider;
  const TransactionsPage({super.key, this.aValider = false});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _liste = GlobalKey<ListePagineeState<TransactionPaiement>>();
  late String _statut = widget.aValider ? 'en_attente' : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements en ligne')),
      body: Column(
        children: [
          Filtres(
            options: [
              ('', 'Toutes'),
              for (final o in refs.options('statut_transaction'))
                (o.code, o.label)
            ],
            valeur: _statut,
            onChange: (v) => setState(() => _statut = v),
          ),
          Expanded(
            child: ListePaginee<TransactionPaiement>(
              key: _liste,
              cle: _statut,
              vide: 'Aucune transaction',
              charger: (page) => di.sl<GetTransactions>()(
                  page: page,
                  statut: _statut.isEmpty ? null : _statut,
                  preuvesSeulement: widget.aValider),
              element: (context, t) => ListTile(
                title: Text(
                    '${nomDe(t.locataire)} · ${refs.libelle('portefeuille', t.portefeuille)}'),
                subtitle: Text(
                    '${refs.libelle('mode_transaction', t.mode)} · ${t.libelleEcheance ?? ''} · ${dateHeure(t.creeLe)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Montant(t.montant,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Statut(FamilleStatut.transaction, 'statut_transaction',
                        t.statut),
                  ],
                ),
                onTap: () async {
                  await ouvrir(context, TransactionDetailPage(id: t.id));
                  _liste.currentState?.recharger();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionDetailPage extends StatelessWidget {
  final String id;
  const TransactionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<TransactionBloc>()..add(LoadTransaction(id)),
      child: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            afficherSucces(context, state.message);
          } else if (state is TransactionActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is TransactionInitial ||
            state is TransactionLoading ||
            state is TransactionLoaded ||
            state is TransactionError,
        builder: (context, state) {
          if (state is TransactionLoaded) {
            return _buildFiche(context, state.transaction);
          }
          return VueChargement(
            titre: 'Transaction',
            failure: state is TransactionError ? state.failure : null,
            onReessayer: () =>
                context.read<TransactionBloc>().add(LoadTransaction(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, TransactionPaiement t) {
    final bloc = context.read<TransactionBloc>();
    final preuve = t.preuve;
    return Scaffold(
      appBar: AppBar(title: Text(t.reference ?? 'Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            children: [
              Ligne(
                'Montant',
                null,
                widget: Montant(t.montant,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              Ligne('Statut', null,
                  widget: Statut(FamilleStatut.transaction,
                      'statut_transaction', t.statut)),
              Ligne('Locataire', nomDe(t.locataire)),
              Ligne('Échéance', t.libelleEcheance ?? '—'),
              Ligne(
                  'Portefeuille', refs.libelle('portefeuille', t.portefeuille)),
              Ligne('Mode', refs.libelle('mode_transaction', t.mode)),
              Ligne('N° de transaction', t.numeroTransaction),
              Ligne('Téléphone payeur', t.telephonePayeur),
              Ligne('Créée le', dateHeure(t.creeLe)),
              if (t.motifRejet != null) Ligne('Motif du rejet', t.motifRejet),
              if (t.referencePaiement != null)
                Ligne('Paiement', t.referencePaiement),
            ],
          ),
          if (preuve != null) ...[
            const SizedBox(height: AppTheme.espaceLg),
            Section(
              titre: 'Preuve de paiement',
              children: [
                InkWell(
                  onTap: () => ouvrirDocument(context, preuve),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.rayon),
                    child: SizedBox(
                      height: 220,
                      child: preuve.estImage
                          ? ImageApi(preuve.id,
                              taille: 'originale', fit: BoxFit.contain)
                          : const Center(
                              child: Icon(Icons.picture_as_pdf_outlined,
                                  size: 48)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (t.aValider) ...[
            const SizedBox(height: AppTheme.espaceLg),
            const Encadre(
                'Vérifiez sur votre relevé Wave / Orange Money que ce montant a bien été reçu avant de valider.'),
            const SizedBox(height: AppTheme.espaceLg),
            FilledButton.icon(
              onPressed: () async {
                final ok = await confirmer(
                  context,
                  titre: 'Valider le paiement',
                  message:
                      'Le paiement sera enregistré et la quittance générée.',
                  action: 'Valider',
                );
                if (ok != null) bloc.add(ValiderTransactionEvent(id));
              },
              icon: const Icon(Icons.check),
              label: const Text('Valider le paiement'),
            ),
            const SizedBox(height: AppTheme.espaceSm),
            OutlinedButton.icon(
              onPressed: () async {
                final motif = await confirmer(
                  context,
                  titre: 'Rejeter la preuve',
                  message: 'Le locataire sera informé du motif.',
                  action: 'Rejeter',
                  danger: true,
                  motif: true,
                );
                if (motif != null) bloc.add(RejeterTransactionEvent(id, motif));
              },
              icon: const Icon(Icons.close),
              label: const Text('Rejeter'),
            ),
          ],
        ],
      ),
    );
  }
}
