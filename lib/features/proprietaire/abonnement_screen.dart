import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session_cubit.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';

/// Abonnement SaaS (§ 31) : plan en cours, consommation, renouvellement par PayDunya.
/// Consultable même abonnement échu : c'est le moyen d'en sortir.
class AbonnementScreen extends StatelessWidget {
  const AbonnementScreen({super.key});

  Future<void> _souscrire(BuildContext context, Map plan, VoidCallback recharger) async {
    var mois = 1;
    String? portefeuille;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Plan ${plan['name']}', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Durée', style: Theme.of(ctx).textTheme.titleMedium),
              Wrap(spacing: 8, children: [
                for (final m in [1, 3, 6, 12])
                  ChoiceChip(label: Text('$m mois'), selected: mois == m, onSelected: (_) => setState(() => mois = m)),
              ]),
              const SizedBox(height: 16),
              Text('Payer avec', style: Theme.of(ctx).textTheme.titleMedium),
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('Au choix'), selected: portefeuille == null, onSelected: (_) => setState(() => portefeuille = null)),
                for (final o in refs.options('portefeuille'))
                  ChoiceChip(label: Text(o.label), selected: portefeuille == o.code, onSelected: (_) => setState(() => portefeuille = o.code)),
              ]),
              const SizedBox(height: 16),
              Ligne('Total', montant(entier(plan['price']) * mois)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Payer')),
            ]),
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final r = await executer(
      context,
      () => api.post<Map<String, dynamic>>('/abonnement/souscrire',
          body: {'plan_code': plan['code'], 'months': mois, 'wallet': ?portefeuille}, idempotence: nouvelleCle()),
    );
    final url = r?['checkout_url'] as String?;
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (context.mounted) {
        afficherSucces(context, 'Après le paiement, revenez ici : votre abonnement sera mis à jour automatiquement.');
      }
    }
    recharger();
    // Le compte en session est relu : la bannière « lecture seule » suit le nouveau statut
    if (context.mounted) context.read<SessionCubit>().chargerCompte().ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Chargeur<List<dynamic>>(
      page: true,
      titre: 'Abonnement',
      charger: () => Future.wait([
        api.get<Map<String, dynamic>>('/abonnement'),
        api.get<Map<String, dynamic>>('/abonnement/plans'),
        api.get<Map<String, dynamic>>('/abonnement/paiements', query: {'limit': 10}),
      ]),
      builder: (context, data, recharger) {
        final a = (data[0] as Map)['abonnement'] as Map;
        final abo = a['abonnement'] as Map?;
        final plan = a['plan'] as Map?;
        final usage = a['usage'] as Map? ?? {};
        final plans = ((data[1] as Map)['plans'] as List).cast<Map>();
        final paiements = ((data[2] as Map)['items'] as List).cast<Map>();

        Widget jauge(String libelle, Map? u) {
          if (u == null) return const SizedBox.shrink();
          final max = u['max'];
          final utilise = entier(u['used']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$libelle : $utilise${max == null ? ' (illimité)' : ' / $max'}'),
              if (max != null) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: (utilise / entier(max)).clamp(0, 1).toDouble(), minHeight: 6),
                ),
              ],
            ]),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Mon abonnement')),
          body: RefreshIndicator(
            onRefresh: recharger,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (a['actif'] != true) ...[
                const Encadre('Abonnement échu ou suspendu : votre espace est en lecture seule. Choisissez un plan pour le réactiver.',
                    ton: TonStatut.danger),
                const SizedBox(height: 16),
              ],
              Section(children: [
                Row(children: [
                  Expanded(child: Text('Plan ${plan?['name'] ?? '—'}', style: Theme.of(context).textTheme.titleLarge)),
                  Statut(FamilleStatut.abonnement, 'statut_abonnement', abo?['status'] as String?),
                ]),
                const SizedBox(height: 8),
                Ligne(abo?['status'] == 'essai' ? "Fin de l'essai" : 'Valable jusqu’au', date(abo?['current_period_end'] as String?)),
                const SizedBox(height: 12),
                jauge('Immeubles', usage['buildings'] as Map?),
                jauge('Appartements', usage['apartments'] as Map?),
                jauge('Messages WhatsApp ce mois', usage['whatsapp_this_month'] as Map?),
              ]),
              const SizedBox(height: 16),
              Text('Choisir un plan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final p in plans)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('${p['name']}', style: Theme.of(context).textTheme.titleMedium)),
                        if (p['code'] == plan?['code']) const Pastille('Plan actuel', ton: TonStatut.info),
                      ]),
                      const SizedBox(height: 4),
                      Text('${montant(p['price'] as num?)} / ${refs.libelle('periode_facturation', p['billing_period'] as String?).toLowerCase()}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600).merge(chiffresFixes)),
                      const SizedBox(height: 8),
                      Text([
                        p['max_buildings'] == null ? 'Immeubles illimités' : '${p['max_buildings']} immeuble(s)',
                        p['max_apartments'] == null ? 'appartements illimités' : '${p['max_apartments']} appartements',
                      ].join(' · ')),
                      if ((p['features'] as List?)?.isNotEmpty == true)
                        Text((p['features'] as List).map((f) => refs.libelle('fonctionnalite', '$f')).join(' · '),
                            style: TextStyle(color: context.palette.texteSecondaire)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: entier(p['price']) == 0 ? null : () => _souscrire(context, p, recharger),
                          child: Text(p['code'] == plan?['code'] ? 'Renouveler' : 'Choisir ce plan'),
                        ),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Paiements', padding: false, children: [
                if (paiements.isEmpty) const ListTile(title: Text('Aucun paiement')),
                for (final p in paiements)
                  ListTile(
                    title: Text('${(p['plan'] as Map?)?['name'] ?? ''} · ${p['months']} mois'),
                    subtitle: Text('${p['reference']} · ${dateHeure((p['paid_at'] ?? p['created_at']) as String?)}'),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Montant(p['amount'] as num?),
                      Text(refs.libelle('statut_paiement_abonnement', p['status'] as String?), style: const TextStyle(fontSize: 12)),
                    ]),
                    onTap: p['status'] == 'initie' && p['checkout_url'] != null
                        ? () => launchUrl(Uri.parse('${p['checkout_url']}'), mode: LaunchMode.externalApplication)
                        : null,
                  ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
