import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/session_cubit.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../commun/notifications_screen.dart';
import 'paiement.dart';

/// Accueil du locataire : « Mon logement », loyer, prochaine échéance, bouton PAYER (§ 28).
class AccueilLocataireScreen extends StatelessWidget {
  const AccueilLocataireScreen({super.key, required this.onAller});
  final ValueChanged<int> onAller;

  @override
  Widget build(BuildContext context) {
    final u = context.watch<SessionCubit>().state.user ?? {};
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour ${u['first_name'] ?? ''}'),
        actions: [
          IconButton(tooltip: 'Notifications', icon: const BoutonNotifications(), onPressed: () => ouvrir(context, const NotificationsScreen())),
        ],
      ),
      body: Chargeur<Map<String, dynamic>>(
        charger: () => api.get<Map<String, dynamic>>('/locataire/accueil'),
        builder: (context, data, recharger) {
          final logements = ((data['homes'] as List?) ?? []).cast<Map>();
          if (logements.isEmpty) {
            return ListView(children: const [Vide('Aucun logement rattaché à votre compte pour le moment.', icone: Icons.home_outlined)]);
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final h in logements) ...[_Logement(h: h, onPaye: recharger, onAller: onAller), const SizedBox(height: AppTheme.espaceLg)],
          ]);
        },
      ),
    );
  }
}

class _Logement extends StatelessWidget {
  const _Logement({required this.h, required this.onPaye, required this.onAller});
  final Map h;
  final VoidCallback onPaye;
  final ValueChanged<int> onAller;

  @override
  Widget build(BuildContext context) {
    final bail = h['lease'] as Map;
    final app = bail['apartment'] as Map? ?? {};
    final immeuble = app['building'] as Map? ?? {};
    final prochaine = h['next_schedule'] as Map?;
    final enRetard = entier(h['amount_overdue']);
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        color: cs.primary,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.espaceLg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MON LOGEMENT', style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text('${immeuble['name'] ?? ''}', style: TextStyle(color: cs.onPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
            Text('Appartement ${app['number'] ?? ''} · ${refs.libelle('type_appartement', app['type'] as String?)}',
                style: TextStyle(color: cs.onPrimary)),
            Text([immeuble['address'], immeuble['city']].whereType<String>().join(', '), style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85))),
            const SizedBox(height: AppTheme.espaceMd),
            Text('Loyer ${montant(entier(bail['rent_amount']) + entier(bail['charges_amount']))} / ${refs.libelle('periodicite', bail['periodicity'] as String?).toLowerCase()}',
                style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w500).merge(chiffresFixes)),
          ]),
        ),
      ),
      const SizedBox(height: AppTheme.espaceMd),
      if (enRetard > 0) ...[
        Encadre('Vous avez ${montant(enRetard)} de loyer en retard.', ton: TonStatut.danger),
        const SizedBox(height: AppTheme.espaceMd),
      ],
      Section(titre: 'Prochaine échéance', children: [
        if (prochaine == null)
          const Text('Vous êtes à jour. Aucune échéance à payer.')
        else ...[
          Row(children: [
            Expanded(child: Text('${prochaine['label']}', style: Theme.of(context).textTheme.titleMedium)),
            Statut(FamilleStatut.echeance, 'statut_echeance', prochaine['status'] as String?),
          ]),
          const SizedBox(height: 8),
          Ligne('À payer avant le', date(prochaine['due_date'] as String?)),
          Ligne('Montant', null,
              widget: Montant(entier(prochaine['amount_due']) - entier(prochaine['amount_paid']),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
          if (entier(h['amount_due']) > entier(prochaine['amount_due']) - entier(prochaine['amount_paid']))
            Ligne('Total dû', montant(h['amount_due'] as num?)),
          const SizedBox(height: AppTheme.espaceMd),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () async {
              if (await payer(context, echeance: prochaine, bailId: '${bail['id']}') == true) onPaye();
            },
            icon: const Icon(Icons.payments_outlined),
            label: const Text('PAYER', style: TextStyle(fontSize: 17, letterSpacing: 1)),
          ),
        ],
      ]),
      const SizedBox(height: AppTheme.espaceMd),
      Row(children: [
        Expanded(child: _Raccourci(Icons.receipt_long_outlined, 'Mon loyer', () => onAller(1))),
        const SizedBox(width: 8),
        Expanded(child: _Raccourci(Icons.report_problem_outlined, 'Signaler un problème', () => onAller(2))),
        const SizedBox(width: 8),
        Expanded(child: _Raccourci(Icons.chat_bubble_outline, 'Écrire', () => onAller(3))),
      ]),
      const SizedBox(height: AppTheme.espaceMd),
      Section(titre: 'Propriétaire', children: [
        Text('${(bail['owner'] as Map?)?['display_name'] ?? ''}'),
        if ((bail['owner'] as Map?)?['phone'] != null)
          Text('${(bail['owner'] as Map)['phone']}', style: TextStyle(color: context.palette.texteSecondaire)),
      ]),
    ]);
  }
}

class _Raccourci extends StatelessWidget {
  const _Raccourci(this.icone, this.libelle, this.onTap);
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(children: [
              Icon(icone, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(libelle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );
}
