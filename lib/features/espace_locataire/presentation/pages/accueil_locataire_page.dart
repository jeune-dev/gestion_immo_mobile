import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/avatar_utilisateur.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/bouton_notifications.dart';
import 'package:gestion_immo_mobile/features/documents/domain/entities/document_app.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/get_documents.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/accueil_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/accueil_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/accueil_locataire_state.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/accords_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/paiement_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/widgets/demarches_locataire.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Accueil du locataire : « Mon logement », loyer, prochaine échéance, bouton PAYER (§ 28).
class AccueilLocatairePage extends StatelessWidget {
  final ValueChanged<int> onAller;
  const AccueilLocatairePage({super.key, required this.onAller});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AccueilLocataireBloc>()..add(LoadAccueilLocataire()),
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: const FondMarque(),
          leading: LogoBarre.siRacine(context),
          leadingWidth: LogoBarre.largeur,

          title: const Text('Mon espace'),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: const BoutonNotifications(),
              onPressed: () => ouvrir(context, const NotificationsPage()),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AvatarUtilisateur(taille: 34, onTap: () => onAller(4)),
            ),
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
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: BandeauAccords(
                            onReponse: () =>
                                bloc.add(RafraichirAccueilLocataire()),
                          ),
                        ),
                        Vide(
                          'Votre logement apparaîtra ici dès que votre propriétaire aura activé votre bail.',
                          icone: Icons.home_outlined,
                          // 3 : onglet Messages.
                          action: OutlinedButton.icon(
                            onPressed: () => onAller(3),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Contacter mon propriétaire'),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        BandeauAccords(
                          onReponse: () =>
                              bloc.add(RafraichirAccueilLocataire()),
                        ),
                        for (final h in logements) ...[
                          VueLogement(
                            h: h,
                            onPaye: () =>
                                bloc.add(RafraichirAccueilLocataire()),
                            onAller: onAller,
                          ),
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

/// Photo du logement : la couverture choisie par le propriétaire, sinon une
/// photo de l'appartement, de l'immeuble, ou la dernière partagée sur le bail.
class _PhotoLogement extends StatefulWidget {
  final LogementLocataire logement;
  const _PhotoLogement({required this.logement});

  @override
  State<_PhotoLogement> createState() => _PhotoLogementState();
}

class _PhotoLogementState extends State<_PhotoLogement> {
  late final Future<DocumentApp?> _photo = _charger();

  Future<DocumentApp?> _charger() async {
    final h = widget.logement;
    if (h.couvertureId != null && h.immeubleId != null) {
      final r = await di.sl<GetDocuments>()(
        type: 'building',
        id: h.immeubleId!,
      );
      final couverture = r
          .fold((_) => const <DocumentApp>[], (p) => p.items)
          .where((d) => d.id == h.couvertureId)
          .firstOrNull;
      if (couverture != null) return couverture;
    }
    final sources = [
      if (h.appartementId != null) ('apartment', h.appartementId!),
      if (h.immeubleId != null) ('building', h.immeubleId!),
      ('lease', h.bailId),
    ];
    for (final (type, id) in sources) {
      final r = await di.sl<GetDocuments>()(type: type, id: id);
      final photo = r
          .fold((_) => const <DocumentApp>[], (p) => p.items)
          .where((d) => d.estImage)
          .firstOrNull;
      if (photo != null) return photo;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentApp?>(
      future: _photo,
      builder: (context, s) {
        final photo = s.data;
        if (photo != null) {
          return GestureDetector(
            onTap: () => afficherImage(context, photo.id),
            child: ImageApi(photo.id, taille: 'originale'),
          );
        }
        return Align(
          alignment: const Alignment(0.82, -0.55),
          child: Icon(
            Icons.home_work_outlined,
            size: 92,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        );
      },
    );
  }
}

/// Bandeau du logement : photo en fond, nom et adresse par-dessus.
class _BandeauLogement extends StatelessWidget {
  final LogementLocataire h;
  const _BandeauLogement({required this.h});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: degradeMarque(context)),
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PhotoLogement(logement: h),
              // Voile : le texte reste lisible sur n'importe quelle photo.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00061730), Color(0xD9061730)],
                      stops: [0.3, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppTheme.espaceLg + 4,
                right: AppTheme.espaceLg + 4,
                bottom: AppTheme.espaceLg,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.immeubleNom ?? 'Mon logement',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Appartement ${h.appartementNumero ?? ''} · ${refs.libelle('type_appartement', h.appartementType)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        [
                          h.immeubleAdresse,
                          h.ville,
                        ].whereType<String>().join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Dans 3 jours », « Aujourd'hui », « En retard de 2 jours » (null si illisible).
String? delaiEcheance(String? dateEcheance, DateTime maintenant) {
  final d = dateEcheance == null ? null : DateTime.tryParse(dateEcheance);
  if (d == null) return null;
  final jours = DateTime(d.year, d.month, d.day)
      .difference(DateTime(maintenant.year, maintenant.month, maintenant.day))
      .inDays;
  if (jours == 0) return 'Aujourd’hui';
  if (jours == 1) return 'Demain';
  if (jours > 1) return 'Dans $jours jours';
  return jours == -1 ? 'En retard d’un jour' : 'En retard de ${-jours} jours';
}

class VueLogement extends StatelessWidget {
  final LogementLocataire h;
  final VoidCallback onPaye;
  final ValueChanged<int> onAller;
  const VueLogement({
    super.key,
    required this.h,
    required this.onPaye,
    required this.onAller,
  });

  @override
  Widget build(BuildContext context) {
    final prochaine = h.prochaineEcheance;
    final p = context.palette;
    final delai = delaiEcheance(prochaine?.dateEcheance, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BandeauLogement(h: h),
        const SizedBox(height: AppTheme.espaceLg),
        if (h.montantEnRetard > 0) ...[
          Encadre(
            'Vous avez ${montant(h.montantEnRetard)} de loyer en retard.',
            ton: TonStatut.danger,
          ),
          const SizedBox(height: AppTheme.espaceLg),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.espaceLg + 4),
            child: prochaine == null
                ? Row(
                    children: [
                      const IconeOption(Icons.check_circle_outline),
                      const SizedBox(width: AppTheme.espaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vous êtes à jour',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Loyer ${montant(h.loyer + h.charges)} · ${refs.libelle('periodicite', h.periodicite).toLowerCase()}',
                              style: TextStyle(color: p.texteSecondaire),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prochaine.libelle ?? 'Prochain loyer',
                              style: TextStyle(
                                color: p.texteSecondaire,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Statut(
                            FamilleStatut.echeance,
                            'statut_echeance',
                            prochaine.statut,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.espaceSm),
                      Montant(
                        prochaine.reste,
                        style: TextStyle(
                          color: p.texte,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.espaceXs),
                      Text(
                        [
                          'Avant le ${date(prochaine.dateEcheance)}',
                          ?delai,
                        ].join(' · '),
                        style: TextStyle(
                          color: p.texteSecondaire,
                          fontSize: 14,
                        ),
                      ),
                      if (h.montantDu > prochaine.reste) ...[
                        const SizedBox(height: AppTheme.espaceXs),
                        Text(
                          'Total dû : ${montant(h.montantDu)}',
                          style: TextStyle(
                            color: p.texte,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.espaceLg),
                      FilledButton.icon(
                        onPressed: () async {
                          if (await payer(
                                context,
                                echeance: prochaine,
                                bailId: h.bailId,
                              ) ==
                              true) {
                            onPaye();
                          }
                        },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Payer mon loyer'),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.espaceLg),
        Row(
          children: [
            Expanded(
              child: _Raccourci(
                Icons.receipt_long_outlined,
                'Mon loyer',
                () => onAller(1),
              ),
            ),
            const SizedBox(width: AppTheme.espaceSm),
            Expanded(
              child: _Raccourci(
                Icons.report_problem_outlined,
                'Signaler un problème',
                () => onAller(2),
              ),
            ),
            const SizedBox(width: AppTheme.espaceSm),
            Expanded(
              child: _Raccourci(
                Icons.chat_bubble_outline,
                'Écrire',
                () => onAller(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.espaceXl),
        GroupeOptions(
          titre: 'Mon propriétaire',
          children: [
            TuileOption(
              icone: Icons.person_outline,
              titre: h.proprietaireNom ?? 'Propriétaire',
              detail: h.proprietaireTelephone,
              fin: h.proprietaireTelephone == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Appeler',
                      icon: Icon(
                        Icons.call_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () =>
                          ouvrirLien(context, 'tel:${h.proprietaireTelephone}'),
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.espaceXl),
        GroupeOptions(
          titre: 'Mon bail',
          children: [
            if (h.sortiePrevue != null)
              TuileOption(
                icone: Icons.event_outlined,
                titre: 'Départ prévu le ${date(h.sortiePrevue)}',
                detail: h.congePar == 'locataire'
                    ? 'Vous avez donné congé · toucher pour le retirer'
                    : 'Congé donné par votre propriétaire',
                onTap: h.congePar == 'locataire'
                    ? () async {
                        if (await retirerCongeLocataire(context, h.bailId)) {
                          onPaye();
                        }
                      }
                    : null,
              )
            else
              TuileOption(
                icone: Icons.logout,
                titre: 'Donner congé',
                detail: h.preavisMois == null || h.preavisMois == 0
                    ? 'Prévenir votre propriétaire de votre départ'
                    : 'Préavis de ${h.preavisMois} mois',
                onTap: () async {
                  if (await donnerCongeLocataire(
                    context,
                    bailId: h.bailId,
                    preavisMois: h.preavisMois,
                  )) {
                    onPaye();
                  }
                },
              ),
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
      child: SizedBox(
        // Hauteur fixe : les trois raccourcis restent alignés (libellés sur 1 ou 2 lignes).
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.palette.primaireTeinte,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              libelle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: context.palette.texte,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
