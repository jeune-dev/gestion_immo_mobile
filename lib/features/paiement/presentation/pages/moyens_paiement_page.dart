import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/paiement/domain/entities/paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/domain/usecases/configurer_moyen_paiement.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/moyens_paiement_bloc.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/moyens_paiement_event.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/bloc/moyens_paiement_state.dart';

/// Moyens de paiement du propriétaire (§ 51.5) : les loyers arrivent sur SON compte.
class MoyensPaiementPage extends StatelessWidget {
  const MoyensPaiementPage({super.key});

  Future<bool> _configurer(BuildContext context,
      {MoyenPaiement? existant}) async {
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Ajouter un moyen de paiement' : 'Modifier',
        initial: existant == null
            ? const {'mode': 'preuve', 'provider': 'wave', 'is_active': true}
            : {
                'provider': existant.fournisseur,
                'mode': existant.mode,
                'label': existant.libelle,
                'account_number': existant.numeroReception,
                'is_active': existant.actif,
              },
        intro: const Text(
          '« Paiement direct avec preuve » : le locataire paie sur votre numéro Wave / Orange Money et déclare sa transaction ; vous la validez.\n'
          '« Paiement intégré » : paiement en ligne via votre compte PayDunya Business, confirmé automatiquement.',
        ),
        champs: [
          const Champ('provider', 'Fournisseur',
              type: TypeChamp.selection,
              referentiel: 'fournisseur_paiement',
              obligatoire: true),
          const Champ('mode', 'Mode',
              type: TypeChamp.selection,
              referentiel: 'mode_transaction',
              obligatoire: true),
          const Champ('label', 'Libellé',
              maxLongueur: 100, indice: 'Ex. Wave personnel'),
          Champ('account_number', 'Numéro de réception',
              type: TypeChamp.telephone, visible: (v) => v['mode'] == 'preuve'),
          Champ('master_key', 'Clé principale PayDunya',
              minLongueur: 8,
              visible: (v) =>
                  v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ('private_key', 'Clé privée PayDunya',
              minLongueur: 8,
              visible: (v) =>
                  v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ('token', 'Jeton PayDunya',
              minLongueur: 8,
              visible: (v) =>
                  v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ(
            'mode_cles',
            'Mode des clés',
            type: TypeChamp.selection,
            options: const [
              OptionRef('live', 'Production'),
              OptionRef('test', 'Test')
            ],
            visible: (v) =>
                v['mode'] == 'integre' && v['provider'] == 'paydunya',
          ),
          Champ('api_key', 'Clé API',
              minLongueur: 8,
              visible: (v) =>
                  v['mode'] == 'integre' && v['provider'] != 'paydunya'),
          Champ('webhook_secret', 'Secret du webhook',
              minLongueur: 8,
              visible: (v) =>
                  v['mode'] == 'integre' && v['provider'] != 'paydunya'),
          const Champ('is_active', 'Actif', type: TypeChamp.interrupteur),
        ],
        messageSucces: 'Moyen de paiement enregistré',
        envoyer: (c) async {
          // Les identifiants sont regroupés dans `credentials` (chiffrés côté serveur, jamais renvoyés)
          final corps = <String, dynamic>{
            for (final k in [
              'provider',
              'mode',
              'label',
              'account_number',
              'is_active'
            ])
              if (c.containsKey(k)) k: c[k],
          };
          // Clés laissées vides sur un moyen existant : `credentials` est omis et
          // l'API conserve les clés déjà enregistrées (sinon 422 sur des clés nulles).
          final cles = c['provider'] == 'paydunya'
              ? const ['master_key', 'private_key', 'token']
              : const ['api_key', 'webhook_secret'];
          if (c['mode'] == 'integre' &&
              (existant == null || cles.any((k) => c[k] != null))) {
            corps['credentials'] = c['provider'] == 'paydunya'
                ? {
                    'master_key': c['master_key'],
                    'private_key': c['private_key'],
                    'token': c['token'],
                    'mode': c['mode_cles'] ?? 'live'
                  }
                : {
                    'api_key': c['api_key'],
                    'webhook_secret': c['webhook_secret']
                  };
          }
          (await di.sl<ConfigurerMoyenPaiement>()(corps)).ouLeve();
          return true;
        },
      ),
    );
    return r != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MoyensPaiementBloc>()..add(LoadMoyensPaiement()),
      child: BlocConsumer<MoyensPaiementBloc, MoyensPaiementState>(
        listener: (context, state) {
          if (state is MoyensPaiementActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is MoyensPaiementInitial ||
            state is MoyensPaiementLoading ||
            state is MoyensPaiementLoaded ||
            state is MoyensPaiementError,
        builder: (context, state) {
          if (state is MoyensPaiementLoaded) {
            return _buildFiche(context, state.moyens);
          }
          return VueChargement(
            titre: 'Moyens de paiement',
            failure: state is MoyensPaiementError ? state.failure : null,
            onReessayer: () =>
                context.read<MoyensPaiementBloc>().add(LoadMoyensPaiement()),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, List<MoyenPaiement> moyens) {
    final bloc = context.read<MoyensPaiementBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Moyens de paiement')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await _configurer(context)) bloc.add(RafraichirMoyensPaiement());
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: moyens.isEmpty
          ? const Vide(
              'Aucun moyen de paiement. Sans configuration, vos locataires ne peuvent payer qu’en espèces.',
              icone: Icons.account_balance_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in moyens)
                  Card(
                    child: ListTile(
                      title: Text(m.libelle ??
                          refs.libelle('fournisseur_paiement', m.fournisseur)),
                      subtitle: Text(
                        '${refs.libelle('mode_transaction', m.mode)}${m.numeroReception != null ? ' · ${m.numeroReception}' : ''}',
                      ),
                      trailing: Pastille(m.actif ? 'Actif' : 'Inactif',
                          ton: m.actif ? TonStatut.succes : TonStatut.neutre),
                      onTap: () async {
                        if (await _configurer(context, existant: m)) {
                          bloc.add(RafraichirMoyensPaiement());
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
