import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/bouton_notifications.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/accueil_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/accueil_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/accueil_locataire_state.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/paiement_page.dart';

/// Accueil du locataire : « Mon logement », loyer, prochaine échéance, bouton PAYER (§ 28).
class AccueilLocatairePage extends StatelessWidget {
  final ValueChanged<int> onAller;
  const AccueilLocatairePage({super.key, required this.onAller});

  @override
  Widget build(BuildContext context) {
    final prenom = context
        .select((AuthBloc b) => b.state.compte?.utilisateur.prenom ?? '');
    return BlocProvider(
      create: (_) => di.sl<AccueilLocataireBloc>()..add(LoadAccueilLocataire()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bonjour $prenom'),
          actions: [
            IconButton(
                tooltip: 'Notifications',
                icon: const BoutonNotifications(),
                onPressed: () => ouvrir(context, const NotificationsPage())),
          ],
        ),
        body: BlocBuilder<AccueilLocataireBloc, AccueilLocataireState>(
          // Un échec de rafraîchissement laisse les logements affichés.
          buildWhen: (_, state) => state is! AccueilLocataireActionError,
          builder: (context, state) {
            final bloc = context.read<AccueilLocataireBloc>();
            if (state is! AccueilLocataireLoaded) {
              return VueChargement(
                failure: state is AccueilLocataireError ? state.failure : null,
                onReessayer: () => bloc.add(LoadAccueilLocataire()),
              );
            }
            final logements = state.logements;
            return RefreshIndicator(
              onRefresh: () async => bloc.add(RafraichirAccueilLocataire()),
              child: logements.isEmpty
                  ? ListView(children: const [
                      Vide(
                          'Aucun logement rattaché à votre compte pour le moment.',
                          icone: Icons.home_outlined)
                    ])
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final h in logements) ...[
                          _Logement(
                              h: h,
                              onPaye: () =>
                                  bloc.add(RafraichirAccueilLocataire()),
                              onAller: onAller),
                          const SizedBox(height: AppTheme.espaceLg),
                        ],
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _Logement extends StatelessWidget {
  final LogementLocataire h;
  final VoidCallback onPaye;
  final ValueChanged<int> onAller;
  const _Logement(
      {required this.h, required this.onPaye, required this.onAller});

  @override
  Widget build(BuildContext context) {
    final prochaine = h.prochaineEcheance;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: cs.primary,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.espaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MON LOGEMENT',
                  style: TextStyle(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  h.immeubleNom ?? '',
                  style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'Appartement ${h.appartementNumero ?? ''} · ${refs.libelle('type_appartement', h.appartementType)}',
                  style: TextStyle(color: cs.onPrimary),
                ),
                Text(
                    [h.immeubleAdresse, h.ville].whereType<String>().join(', '),
                    style:
                        TextStyle(color: cs.onPrimary.withValues(alpha: 0.85))),
                const SizedBox(height: AppTheme.espaceMd),
                Text(
                  'Loyer ${montant(h.loyer + h.charges)} / ${refs.libelle('periodicite', h.periodicite).toLowerCase()}',
                  style: TextStyle(
                          color: cs.onPrimary, fontWeight: FontWeight.w500)
                      .merge(chiffresFixes),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.espaceMd),
        if (h.montantEnRetard > 0) ...[
          Encadre('Vous avez ${montant(h.montantEnRetard)} de loyer en retard.',
              ton: TonStatut.danger),
          const SizedBox(height: AppTheme.espaceMd),
        ],
        Section(
          titre: 'Prochaine échéance',
          children: [
            if (prochaine == null)
              const Text('Vous êtes à jour. Aucune échéance à payer.')
            else ...[
              Row(
                children: [
                  Expanded(
                      child: Text(prochaine.libelle ?? '',
                          style: Theme.of(context).textTheme.titleMedium)),
                  Statut(FamilleStatut.echeance, 'statut_echeance',
                      prochaine.statut),
                ],
              ),
              const SizedBox(height: 8),
              Ligne('À payer avant le', date(prochaine.dateEcheance)),
              Ligne(
                'Montant',
                null,
                widget: Montant(prochaine.reste,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
              ),
              if (h.montantDu > prochaine.reste)
                Ligne('Total dû', montant(h.montantDu)),
              const SizedBox(height: AppTheme.espaceMd),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
                onPressed: () async {
                  if (await payer(context,
                          echeance: prochaine, bailId: h.bailId) ==
                      true) {
                    onPaye();
                  }
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text('PAYER',
                    style: TextStyle(fontSize: 17, letterSpacing: 1)),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.espaceMd),
        Row(
          children: [
            Expanded(
                child: _Raccourci(Icons.receipt_long_outlined, 'Mon loyer',
                    () => onAller(1))),
            const SizedBox(width: 8),
            Expanded(
                child: _Raccourci(Icons.report_problem_outlined,
                    'Signaler un problème', () => onAller(2))),
            const SizedBox(width: 8),
            Expanded(
                child: _Raccourci(
                    Icons.chat_bubble_outline, 'Écrire', () => onAller(3))),
          ],
        ),
        const SizedBox(height: AppTheme.espaceMd),
        Section(
          titre: 'Propriétaire',
          children: [
            Text(h.proprietaireNom ?? ''),
            if (h.proprietaireTelephone != null)
              Text(h.proprietaireTelephone!,
                  style: TextStyle(color: context.palette.texteSecondaire)),
          ],
        ),
      ],
    );
  }
}

class _Raccourci extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  const _Raccourci(this.icone, this.libelle, this.onTap);

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Icon(icone, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 6),
                Text(libelle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}
