import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/bail/presentation/pages/bail_detail_page.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/entities/locataire.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/bloc/locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/bloc/locataire_event.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/bloc/locataire_state.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/widgets/dialogue_invitation.dart';
import 'package:gestion_immo_mobile/features/locataire/presentation/widgets/formulaire_locataire.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/conversation_page.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;

/// La fiche d'un locataire : coordonnées, compte application, solde, baux,
/// derniers paiements et documents.
class LocataireDetailPage extends StatelessWidget {
  final String id;

  const LocataireDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<LocataireBloc>()..add(LoadLocataire(id)),
      child: _LocataireDetailView(id: id),
    );
  }
}

class _LocataireDetailView extends StatefulWidget {
  final String id;
  const _LocataireDetailView({required this.id});

  @override
  State<_LocataireDetailView> createState() => _LocataireDetailViewState();
}

class _LocataireDetailViewState extends State<_LocataireDetailView> {
  // Dernière fiche lue : le dialogue d'invitation en a besoin (prénom,
  // téléphone) alors que l'état courant ne porte que le code.
  Locataire? _locataire;

  void _rafraichir() {
    context.read<LocataireBloc>().add(RafraichirLocataire(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocataireBloc, LocataireState>(
      listener: (context, state) {
        if (state is LocataireLoaded) {
          _locataire = state.locataire;
        } else if (state is LocataireSuccess) {
          afficherSucces(context, state.message);
        } else if (state is LocataireActionError) {
          afficherErreurApi(context, state.failure);
        } else if (state is LocataireInvitationLoaded && _locataire != null) {
          afficherInvitation(context, state.invitation, _locataire!);
        } else if (state is LocataireSupprime) {
          afficherSucces(context, state.message);
          Navigator.of(context).pop(true);
        }
      },
      // Les états d'action (message, invitation…) ne redessinent pas l'écran :
      // la fiche reste affichée pendant et après l'action.
      buildWhen: (_, state) =>
          state is LocataireInitial ||
          state is LocataireLoading ||
          state is LocataireLoaded ||
          state is LocataireError,
      builder: (context, state) {
        if (state is LocataireLoaded) {
          return _buildFiche(context, state.locataire);
        }
        return VueChargement(
          titre: 'Locataire',
          failure: state is LocataireError ? state.failure : null,
          onReessayer: () =>
              context.read<LocataireBloc>().add(LoadLocataire(widget.id)),
        );
      },
    );
  }

  Widget _buildFiche(BuildContext context, Locataire t) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.nomComplet),
        actions: [
          IconButton(
            tooltip: 'Écrire au locataire',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => ouvrir(
              context,
              ConversationPage.proprietaire(
                locataireId: widget.id,
                titre: t.nomComplet,
              ),
            ),
          ),
          _buildMenu(context, t),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _rafraichir(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Coordonnées et compte ──────────────────────────────────────
            _buildIdentite(context, t),
            const SizedBox(height: AppTheme.espaceLg),

            // ── Solde ──────────────────────────────────────────────────────
            _buildSolde(t.solde),
            const SizedBox(height: AppTheme.espaceLg),

            // ── Baux ───────────────────────────────────────────────────────
            _buildBaux(context, t.baux),
            const SizedBox(height: AppTheme.espaceLg),

            // ── Derniers paiements ─────────────────────────────────────────
            _buildPaiements(t.paiementsRecents),
            const SizedBox(height: AppTheme.espaceLg),

            // ── Documents ──────────────────────────────────────────────────
            SectionDocuments(type: 'tenant', id: widget.id),
          ],
        ),
      ),
    );
  }

  // ── Menu « Modifier / Supprimer » ──────────────────────────────────────────
  Widget _buildMenu(BuildContext context, Locataire t) {
    return MenuActions(
      actions: [
        (
          'Modifier',
          () async {
            if (await modifierLocataire(context, t) != null) _rafraichir();
          },
          false,
        ),
        (
          'Supprimer',
          () async {
            final bloc = context.read<LocataireBloc>();
            final ok = await confirmer(
              context,
              titre: 'Supprimer le locataire',
              message: 'Un locataire qui a un historique (bail, paiements) '
                  'ne peut pas être supprimé.',
              action: 'Supprimer',
              danger: true,
            );
            if (ok != null) bloc.add(SupprimerLocataireEvent(widget.id));
          },
          true,
        ),
      ],
    );
  }

  // ── Coordonnées, compte application, WhatsApp ──────────────────────────────
  Widget _buildIdentite(BuildContext context, Locataire t) {
    final bloc = context.read<LocataireBloc>();
    return Section(
      children: [
        Ligne('Téléphone', t.telephone ?? ''),
        Ligne('E-mail', t.email),
        Ligne(
          "Pièce d'identité",
          t.typePiece == null
              ? null
              : '${refs.libelle('type_piece_identite', t.typePiece)} '
                  '${t.numeroPiece ?? ''}',
        ),
        Ligne(
          'Compte application',
          null,
          widget: t.compteActif
              ? const Pastille('Activé', ton: TonStatut.succes)
              : Pastille(
                  t.invitationEnvoyee ? 'Invitation envoyée' : 'Non activé',
                  ton: TonStatut.neutre,
                ),
        ),
        Ligne(
          'WhatsApp',
          null,
          widget: Pastille(
            t.consentementWhatsapp
                ? 'Consentement donné'
                : 'Pas de consentement',
            ton: t.consentementWhatsapp ? TonStatut.succes : TonStatut.neutre,
          ),
        ),
        if (t.notes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.notes!),
          ),
        const SizedBox(height: AppTheme.espaceSm),
        Wrap(
          spacing: AppTheme.espaceSm,
          runSpacing: AppTheme.espaceSm,
          children: [
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${t.telephone}')),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Appeler'),
            ),
            if (!t.compteActif)
              OutlinedButton.icon(
                onPressed: () => bloc.add(InviterLocataireEvent(widget.id)),
                icon: const Icon(Icons.key_outlined),
                label: Text(
                  t.invitationEnvoyee
                      ? 'Nouveau code'
                      : 'Inviter dans l’application',
                ),
              ),
            if (!t.consentementWhatsapp)
              TextButton(
                onPressed: () async {
                  final ok = await confirmer(
                    context,
                    titre: 'Consentement WhatsApp',
                    message: 'Confirmez que le locataire a accepté de recevoir '
                        'relances et confirmations par WhatsApp.',
                  );
                  if (ok != null) {
                    bloc.add(EnregistrerConsentementWhatsappEvent(widget.id));
                  }
                },
                child: const Text('Enregistrer le consentement WhatsApp'),
              ),
          ],
        ),
      ],
    );
  }

  // ── Solde ──────────────────────────────────────────────────────────────────
  Widget _buildSolde(SoldeLocataire solde) {
    return Section(
      titre: 'Solde',
      children: [
        Ligne('Reste dû', montant(solde.resteDu)),
        Ligne('Impayés', montant(solde.impayes)),
        Ligne('Échéances en retard', '${solde.echeancesEnRetard}'),
      ],
    );
  }

  // ── Baux ───────────────────────────────────────────────────────────────────
  Widget _buildBaux(BuildContext context, List<BailDuLocataire> baux) {
    return Section(
      titre: 'Baux',
      padding: false,
      children: baux.isEmpty
          ? [const ListTile(title: Text('Aucun bail'))]
          : [
              for (final b in baux)
                ListTile(
                  title: Text(
                    '${b.reference ?? ''} · ${b.logement?.numero ?? ''}',
                  ),
                  subtitle: Text(
                    '${b.logement?.immeubleNom ?? ''} · ${montant(b.loyer)}',
                  ),
                  trailing: Statut(FamilleStatut.bail, 'statut_bail', b.statut),
                  onTap: () async {
                    await ouvrir(context, BailDetailPage(id: b.id));
                    _rafraichir();
                  },
                ),
            ],
    );
  }

  // ── Derniers paiements ─────────────────────────────────────────────────────
  Widget _buildPaiements(List<PaiementRecent> paiements) {
    return Section(
      titre: 'Derniers paiements',
      padding: false,
      children: [
        for (final p in paiements)
          ListTile(
            dense: true,
            title: Text(p.reference ?? ''),
            subtitle: Text(
              '${date(p.date)} · ${refs.libelle('mode_paiement', p.moyen)}',
            ),
            trailing: Montant(p.montant),
          ),
        if (paiements.isEmpty) const ListTile(title: Text('Aucun paiement')),
      ],
    );
  }
}
