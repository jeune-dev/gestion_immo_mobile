import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_cubit.dart';
import '../../core/format.dart';
import '../../core/referentiels.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/formulaire.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../commun/compte.dart';
import '../commun/notifications_screen.dart';
import '../commun/synchronisation.dart';
import 'messagerie_screen.dart';

/// Onglet « Profil » du propriétaire.
class ProfilProprietaireScreen extends StatelessWidget {
  const ProfilProprietaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionCubit>().state;
    final u = s.user ?? {};
    final owner = s.owner ?? {};
    final abo = s.abonnement ?? {};
    Widget tuile(IconData i, String t, VoidCallback onTap, {String? sous, Widget? fin}) => ListTile(
          leading: Icon(i),
          title: Text(t),
          subtitle: sous == null ? null : Text(sous),
          trailing: fin ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(radius: 28, child: Text(initiales(u), style: const TextStyle(fontSize: 18))),
            title: Text(nomComplet(u), style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text([owner['company_name'], u['phone'], u['email']].whereType<String>().join('\n')),
            trailing: IconButton(tooltip: 'Modifier', icon: const Icon(Icons.edit_outlined), onPressed: () => modifierCompte(context)),
          ),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Card(
          child: Column(children: [
            tuile(Icons.workspace_premium_outlined, 'Abonnement', () => context.push('/p/abonnement'),
                sous: '${(abo['plan'] as Map?)?['name'] ?? ''} · jusqu’au ${date((abo['abonnement'] as Map?)?['current_period_end'] as String?)}',
                fin: Statut(FamilleStatut.abonnement, 'statut_abonnement', (abo['abonnement'] as Map?)?['status'] as String?)),
            tuile(Icons.store_outlined, 'Mon espace propriétaire', () => _espace(context), sous: 'Nom affiché, coordonnées sur les quittances'),
            tuile(Icons.tune, 'Relances et règles de gestion', () => ouvrir(context, const ParametresScreen())),
            tuile(Icons.account_balance_outlined, 'Moyens de paiement', () => ouvrir(context, const MoyensPaiementScreen()),
                sous: 'Wave, Orange Money, PayDunya'),
            tuile(Icons.category_outlined, 'Catégories de dépenses', () => ouvrir(context, const CategoriesScreen())),
          ]),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Card(
          child: Column(children: [
            tuile(Icons.chat_bubble_outline, 'Messagerie', () => ouvrir(context, const MessagerieScreen())),
            tuile(Icons.notifications_outlined, 'Notifications', () => ouvrir(context, const NotificationsScreen())),
            tuile(Icons.lock_outline, 'Sécurité', () => ouvrir(context, const SecuriteScreen())),
            ListenableBuilder(
              listenable: Services.fileAttente,
              builder: (context, _) => Services.fileAttente.operations.isEmpty
                  ? const SizedBox.shrink()
                  : tuile(Icons.cloud_upload_outlined, 'Opérations en attente', () => ouvrir(context, const OperationsScreen()),
                      fin: Badge(label: Text('${Services.fileAttente.operations.length}'))),
            ),
          ]),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await confirmer(context, titre: 'Se déconnecter', message: 'Les données enregistrées sur ce téléphone seront effacées.', action: 'Se déconnecter');
            if (ok != null && context.mounted) await context.read<SessionCubit>().deconnecter();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
      ]),
    );
  }

  Future<void> _espace(BuildContext context) async {
    final cubit = context.read<SessionCubit>();
    final r = await api.get<Map<String, dynamic>>('/parametres');
    if (!context.mounted) return;
    await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Mon espace propriétaire',
        initial: Map<String, dynamic>.from(r['owner'] as Map),
        champs: const [
          Champ('display_name', 'Nom affiché', obligatoire: true, maxLongueur: 150),
          Champ('company_name', 'Société', maxLongueur: 150),
          Champ('phone', 'Téléphone', type: TypeChamp.telephone),
          Champ('email', 'E-mail', type: TypeChamp.email),
          Champ('address', 'Adresse', maxLongueur: 255),
          Champ('city', 'Ville', maxLongueur: 100),
        ],
        messageSucces: 'Espace mis à jour',
        envoyer: (c) async {
          await api.patch<dynamic>('/parametres/profil', body: c);
          await cubit.chargerCompte();
          return true;
        },
      ),
    );
  }
}

/// Règles de gestion du propriétaire (relances § 14, état des lieux § 52.4, caution § 55, canaux § 54.3).
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  static const _delais = [-7, -3, -1, 0, 1, 3, 7, 15, 30];

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Règles de gestion',
      charger: () => api.get<Map<String, dynamic>>('/parametres', cache: false),
      builder: (context, data, recharger) {
        final s = Map<String, dynamic>.from(data['settings'] as Map);
        final relances = ((s['reminder_offsets'] as List?) ?? []).map((e) => entier(e)).toSet();
        final canaux = ((s['channel_order'] as List?) ?? []).map((e) => '$e').toList();

        Future<void> maj(Map<String, dynamic> corps) async {
          await executer(context, () => api.patch<dynamic>('/parametres', body: corps), succes: 'Paramètre enregistré');
          recharger();
        }

        Future<void> entierChamp(String cle, String titre, int min, int max) async {
          final r = await EcranFormulaire.ouvrir<Map>(
            context,
            EcranFormulaire(
              titre: titre,
              initial: s,
              champs: [Champ(cle, titre, type: TypeChamp.entier, obligatoire: true, min: min, max: max)],
              envoyer: (c) async => (await api.patch<Map<String, dynamic>>('/parametres', body: c)),
              messageSucces: 'Paramètre enregistré',
            ),
          );
          if (r != null) recharger();
        }

        String libelleDelai(int j) => j < 0 ? 'J$j' : j == 0 ? 'Jour J' : 'J+$j';

        return Scaffold(
          appBar: AppBar(title: const Text('Règles de gestion')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(titre: 'Relances automatiques de loyer', children: [
              const Text('Le locataire est relancé avant et après la date d’échéance aux jours choisis.'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final j in _delais)
                  FilterChip(
                    label: Text(libelleDelai(j)),
                    selected: relances.contains(j),
                    onSelected: (v) {
                      final n = {...relances};
                      v ? n.add(j) : n.remove(j);
                      if (n.isEmpty) return afficherErreur(context, 'Gardez au moins une relance');
                      maj({'reminder_offsets': (n.toList()..sort())});
                    },
                  ),
              ]),
            ]),
            const SizedBox(height: AppTheme.espaceLg),
            Card(
              child: Column(children: [
                ListTile(
                  title: const Text('Préavis avant échéance'),
                  subtitle: Text('${s['schedule_notice_days']} jour(s) avant, l’échéance passe « À payer »'),
                  onTap: () => entierChamp('schedule_notice_days', 'Préavis (jours)', 0, 30),
                ),
                ListTile(
                  title: const Text('Délai de grâce'),
                  subtitle: Text('« En retard » ${s['late_grace_days']} jour(s) après l’échéance'),
                  onTap: () => entierChamp('late_grace_days', 'Délai de grâce (jours)', 0, 30),
                ),
                ListTile(
                  title: const Text("Délai de réponse à l'état des lieux"),
                  subtitle: Text('${s['inspection_response_days']} jour(s), puis acceptation tacite'),
                  onTap: () => entierChamp('inspection_response_days', 'Délai de réponse (jours)', 1, 60),
                ),
                ListTile(
                  title: const Text('Restitution de la caution'),
                  subtitle: Text('Sous ${s['deposit_refund_days']} jour(s) après la fin du bail'),
                  onTap: () => entierChamp('deposit_refund_days', 'Délai de restitution (jours)', 1, 180),
                ),
              ]),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Section(titre: "État des lieux d'entrée avant l'activation du bail", children: [
              RadioGroup<String>(
                groupValue: s['entry_inspection_policy'] as String?,
                onChanged: (v) => maj({'entry_inspection_policy': v}),
                child: Column(children: [
                  for (final o in refs.options('politique_edl_entree'))
                    RadioListTile<String>(contentPadding: EdgeInsets.zero, title: Text(o.label), value: o.code),
                ]),
              ),
            ]),
            const SizedBox(height: AppTheme.espaceLg),
            Section(titre: 'Canaux de notification des locataires', children: [
              const Text('Ordre d’essai des canaux (WhatsApp uniquement avec le consentement du locataire).'),
              for (final c in const [OptionRef('push', 'Notification push'), OptionRef('whatsapp', 'WhatsApp'), OptionRef('sms', 'SMS')])
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.label),
                  subtitle: canaux.contains(c.code) ? Text('Position ${canaux.indexOf(c.code) + 1}') : null,
                  value: canaux.contains(c.code),
                  onChanged: (v) {
                    final n = [...canaux];
                    v == true ? n.add(c.code) : n.remove(c.code);
                    if (n.isEmpty) return afficherErreur(context, 'Gardez au moins un canal');
                    maj({'channel_order': n});
                  },
                ),
              const Divider(),
              RadioGroup<String>(
                groupValue: s['notification_strategy'] as String?,
                onChanged: (v) => maj({'notification_strategy': v}),
                child: Column(children: [
                  for (final o in refs.options('strategie_envoi'))
                    RadioListTile<String>(contentPadding: EdgeInsets.zero, title: Text(o.label), value: o.code),
                ]),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

/// Moyens de paiement du propriétaire (§ 51.5) : les loyers arrivent sur SON compte.
class MoyensPaiementScreen extends StatelessWidget {
  const MoyensPaiementScreen({super.key});

  Future<bool> _configurer(BuildContext context, {Map? existant}) async {
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Ajouter un moyen de paiement' : 'Modifier',
        initial: existant == null ? const {'mode': 'preuve', 'provider': 'wave', 'is_active': true} : Map<String, dynamic>.from(existant),
        intro: const Text(
            '« Paiement direct avec preuve » : le locataire paie sur votre numéro Wave / Orange Money et déclare sa transaction ; vous la validez.\n'
            '« Paiement intégré » : paiement en ligne via votre compte PayDunya Business, confirmé automatiquement.'),
        champs: [
          const Champ('provider', 'Fournisseur', type: TypeChamp.selection, referentiel: 'fournisseur_paiement', obligatoire: true),
          const Champ('mode', 'Mode', type: TypeChamp.selection, referentiel: 'mode_transaction', obligatoire: true),
          const Champ('label', 'Libellé', maxLongueur: 100, indice: 'Ex. Wave personnel'),
          Champ('account_number', 'Numéro de réception', type: TypeChamp.telephone, visible: (v) => v['mode'] == 'preuve'),
          Champ('master_key', 'Clé principale PayDunya', visible: (v) => v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ('private_key', 'Clé privée PayDunya', visible: (v) => v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ('token', 'Jeton PayDunya', visible: (v) => v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ('mode_cles', 'Mode des clés', type: TypeChamp.selection, options: const [OptionRef('live', 'Production'), OptionRef('test', 'Test')],
              visible: (v) => v['mode'] == 'integre' && v['provider'] == 'paydunya'),
          Champ('api_key', 'Clé API', visible: (v) => v['mode'] == 'integre' && v['provider'] != 'paydunya'),
          Champ('webhook_secret', 'Secret du webhook', visible: (v) => v['mode'] == 'integre' && v['provider'] != 'paydunya'),
          const Champ('is_active', 'Actif', type: TypeChamp.interrupteur),
        ],
        messageSucces: 'Moyen de paiement enregistré',
        envoyer: (c) {
          // Les identifiants sont regroupés dans `credentials` (chiffrés côté serveur, jamais renvoyés)
          final corps = <String, dynamic>{
            for (final k in ['provider', 'mode', 'label', 'account_number', 'is_active'])
              if (c.containsKey(k)) k: c[k],
          };
          // Clés laissées vides sur un moyen existant : `credentials` est omis et
          // l'API conserve les clés déjà enregistrées (sinon 422 sur des clés nulles).
          final cles = c['provider'] == 'paydunya' ? const ['master_key', 'private_key', 'token'] : const ['api_key', 'webhook_secret'];
          if (c['mode'] == 'integre' && (existant == null || cles.any((k) => c[k] != null))) {
            corps['credentials'] = c['provider'] == 'paydunya'
                ? {'master_key': c['master_key'], 'private_key': c['private_key'], 'token': c['token'], 'mode': c['mode_cles'] ?? 'live'}
                : {'api_key': c['api_key'], 'webhook_secret': c['webhook_secret']};
          }
          return api.put<Map<String, dynamic>>('/paiements/moyens', body: corps);
        },
      ),
    );
    return r != null;
  }

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Moyens de paiement',
      charger: () => api.get<Map<String, dynamic>>('/paiements/moyens', cache: false),
      builder: (context, data, recharger) {
        final moyens = (data['providers'] as List).cast<Map>();
        return Scaffold(
          appBar: AppBar(title: const Text('Moyens de paiement')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              if (await _configurer(context)) recharger();
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          body: moyens.isEmpty
              ? const Vide('Aucun moyen de paiement. Sans configuration, vos locataires ne peuvent payer qu’en espèces.',
                  icone: Icons.account_balance_outlined)
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final m in moyens)
                    Card(
                      child: ListTile(
                        title: Text('${m['label'] ?? refs.libelle('fournisseur_paiement', m['provider'] as String?)}'),
                        subtitle: Text('${refs.libelle('mode_transaction', m['mode'] as String?)}${m['account_number'] != null ? ' · ${m['account_number']}' : ''}'),
                        trailing: Pastille(m['is_active'] == true ? 'Actif' : 'Inactif', ton: m['is_active'] == true ? TonStatut.succes : TonStatut.neutre),
                        onTap: () async {
                          if (await _configurer(context, existant: m)) recharger();
                        },
                      ),
                    ),
                ]),
        );
      },
    );
  }
}

/// Catégories de dépenses : catalogue commun + catégories propres au propriétaire.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Catégories de dépenses',
      charger: () => api.get<Map<String, dynamic>>('/categories-depenses', query: {'inclure_inactives': true}, cache: false),
      builder: (context, data, recharger) {
        final cats = (data['categories'] as List).cast<Map>();
        Future<void> formulaire({Map? existant}) async {
          final r = await EcranFormulaire.ouvrir<Map>(
            context,
            EcranFormulaire(
              titre: existant == null ? 'Nouvelle catégorie' : 'Modifier la catégorie',
              initial: existant == null ? const {} : Map<String, dynamic>.from(existant),
              champs: const [
                Champ('name', 'Nom', obligatoire: true, maxLongueur: 100),
                Champ('cash_group', 'Groupe de caisse', type: TypeChamp.selection, referentiel: 'groupe_caisse_sortie', obligatoire: true),
              ],
              messageSucces: 'Catégorie enregistrée',
              envoyer: (c) => existant == null
                  ? api.post<Map<String, dynamic>>('/categories-depenses', body: c)
                  : api.patch<Map<String, dynamic>>('/categories-depenses/${existant['id']}', body: c),
            ),
          );
          if (r != null) recharger();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Catégories de dépenses')),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => formulaire(), icon: const Icon(Icons.add), label: const Text('Catégorie')),
          body: ListView(padding: const EdgeInsets.fromLTRB(0, 8, 0, 96), children: [
            for (final c in cats)
              ListTile(
                title: Text('${c['name']}'),
                subtitle: Text('${refs.libelle('groupe_caisse_sortie', c['cash_group'] as String?)}${c['owner_id'] == null ? ' · catalogue' : ''}'),
                trailing: c['is_active'] == true
                    ? (c['owner_id'] == null
                        ? null
                        : IconButton(
                            tooltip: 'Désactiver',
                            icon: const Icon(Icons.visibility_off_outlined),
                            onPressed: () async {
                              await executer(context, () => api.post<dynamic>('/categories-depenses/${c['id']}/desactiver'), succes: 'Catégorie désactivée');
                              recharger();
                            },
                          ))
                    : const Pastille('Inactive'),
                onTap: c['owner_id'] == null ? null : () => formulaire(existant: c),
              ),
          ]),
        );
      },
    );
  }
}
