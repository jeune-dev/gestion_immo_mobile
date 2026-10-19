import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session_cubit.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../commun/compte.dart';
import '../commun/notifications_screen.dart';
import '../proprietaire/finances/quittances_screen.dart';
import 'paiement.dart';

/// Profil du locataire : caution, charges, quittances, consentement WhatsApp, sécurité.
class ProfilLocataireScreen extends StatelessWidget {
  const ProfilLocataireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<SessionCubit>().state.user ?? {};
    Widget tuile(IconData i, String t, VoidCallback onTap, {String? sous}) =>
        ListTile(leading: Icon(i), title: Text(t), subtitle: sous == null ? null : Text(sous), trailing: const Icon(Icons.chevron_right), onTap: onTap);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(radius: 28, child: Text(initiales(u))),
            title: Text(nomComplet(u), style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text([u['phone'], u['email']].whereType<String>().join('\n')),
            trailing: IconButton(tooltip: 'Modifier', icon: const Icon(Icons.edit_outlined), onPressed: () => modifierCompte(context)),
          ),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Card(
          child: Column(children: [
            tuile(Icons.description_outlined, 'Mes quittances', () => ouvrir(context, const QuittancesScreen(chemin: '/locataire/quittances'))),
            tuile(Icons.savings_outlined, 'Ma caution', () => ouvrir(context, const CautionLocataireScreen())),
            tuile(Icons.water_drop_outlined, 'Mes charges', () => ouvrir(context, const ChargesLocataireScreen()), sous: 'Eau, électricité… refacturées'),
          ]),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Card(
          child: Column(children: [
            tuile(Icons.notifications_outlined, 'Notifications', () => ouvrir(context, const NotificationsScreen())),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Relances par WhatsApp'),
              subtitle: const Text('Rappels de loyer et confirmations de paiement'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final choix = await showModalBottomSheet<bool>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const ListTile(title: Text('Recevoir les messages WhatsApp de votre propriétaire ?')),
                      ListTile(leading: const Icon(Icons.check), title: const Text("J'accepte"), onTap: () => Navigator.pop(ctx, true)),
                      ListTile(leading: const Icon(Icons.close), title: const Text('Je refuse'), onTap: () => Navigator.pop(ctx, false)),
                    ]),
                  ),
                );
                if (choix == null || !context.mounted) return;
                await executer(context, () => api.post<dynamic>('/locataire/consentement-whatsapp', body: {'accorde': choix}),
                    succes: choix ? 'Consentement enregistré' : 'Consentement retiré');
              },
            ),
            tuile(Icons.lock_outline, 'Sécurité', () => ouvrir(context, const SecuriteScreen())),
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
}

/// Ma caution (§ 55) : montants et contestation d'une retenue.
class CautionLocataireScreen extends StatelessWidget {
  const CautionLocataireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Ma caution',
      charger: () => api.get<Map<String, dynamic>>('/locataire/caution', cache: false),
      builder: (context, data, recharger) {
        final cautions = ((data['deposits'] as List?) ?? []).cast<Map>();
        return Scaffold(
          appBar: AppBar(title: const Text('Ma caution')),
          body: cautions.isEmpty
              ? const Vide('Aucune caution', icone: Icons.savings_outlined)
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final c in cautions) ...[
                    Section(children: [
                      Row(children: [
                        Expanded(child: Text('Bail ${(c['lease'] as Map?)?['reference'] ?? ''}', style: Theme.of(context).textTheme.titleMedium)),
                        Statut(FamilleStatut.caution, 'statut_caution', c['status'] as String?),
                      ]),
                      const SizedBox(height: 8),
                      Ligne('Montant prévu', montant(c['amount_expected'] as num?)),
                      Ligne('Versé', montant(c['amount_received'] as num?)),
                      Ligne('Retenu', montant(c['amount_withheld'] as num?)),
                      Ligne('Restitué', montant(c['amount_refunded'] as num?)),
                      Ligne('Détenu par le propriétaire', montant(c['balance'] as num?)),
                    ]),
                    for (final t in ((c['transactions'] as List?) ?? []).cast<Map>().where((t) => t['type'] == 'retenue'))
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Text('Retenue de ${montant(t['amount'] as num?)} · ${refs.libelle('motif_retenue', t['reason'] as String?)}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (t['description'] != null) Text('${t['description']}'),
                            if (t['contest_status'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Contestation : ${refs.libelle('statut_contestation', t['contest_status'] as String?)}'
                                    '${t['owner_response'] != null ? '\nRéponse : ${t['owner_response']}' : ''}'),
                              )
                            else
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () async {
                                    final msg = await confirmer(context,
                                        titre: 'Contester la retenue',
                                        message: 'Expliquez pourquoi vous contestez (10 caractères minimum). La caution passe en litige.',
                                        motif: true,
                                        minMotif: 10,
                                        libelleMotif: 'Votre message',
                                        action: 'Contester');
                                    if (msg == null || !context.mounted) return;
                                    await executer(context, () => api.post<dynamic>('/locataire/caution/retenues/${t['id']}/contester', body: {'message': msg}),
                                        succes: 'Contestation envoyée');
                                    recharger();
                                  },
                                  child: const Text('Contester cette retenue'),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ]),
        );
      },
    );
  }
}

/// Mes charges (§ 28) : quote-part des factures communes, payable comme un loyer.
class ChargesLocataireScreen extends StatelessWidget {
  const ChargesLocataireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes charges')),
      body: ListePaginee(
        vide: 'Aucune charge',
        iconeVide: Icons.water_drop_outlined,
        charger: (page) => api.get('/locataire/charges', query: {'page': page, 'tri': '-due_date'}),
        element: (context, c) {
          final reste = entier(c['amount']) - entier(c['amount_paid']);
          final payable = ['a_payer', 'partiellement_paye', 'en_retard'].contains(c['status']);
          return ListTile(
            title: Text('${c['label']}'),
            subtitle: Text('${refs.libelle('type_charge', c['charge_type'] as String?)} · échéance ${date(c['due_date'] as String?)}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Montant(payable ? reste : entier(c['amount']), style: const TextStyle(fontWeight: FontWeight.w600)),
              Statut(FamilleStatut.charge, 'statut_charge', c['status'] as String?),
            ]),
            onTap: payable ? () => _payerCharge(context, c) : null,
          );
        },
      ),
    );
  }

  Future<void> _payerCharge(BuildContext context, Map c) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text('Payer ${montant(entier(c['amount']) - entier(c['amount_paid']))}')),
          for (final o in refs.options('portefeuille'))
            ListTile(leading: const Icon(Icons.phone_iphone), title: Text('Avec ${o.label}'), onTap: () => Navigator.pop(ctx, o.code)),
        ]),
      ),
    );
    if (choix == null || !context.mounted) return;
    final r = await executer(context,
        () => api.post<Map<String, dynamic>>('/locataire/paiements', body: {'charge_id': c['id'], 'wallet': choix}, idempotence: nouvelleCle()));
    if (r?['checkout_url'] != null && context.mounted) {
      await ouvrirPaiement(context, '${(r!['transaction'] as Map)['id']}', r['checkout_url'] as String);
    }
  }
}
