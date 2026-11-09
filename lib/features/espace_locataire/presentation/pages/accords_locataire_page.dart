import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/telecharger_document.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/accords.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/accords_locataire.dart';

/// Bandeau de l'accueil : un bail ou un nouveau loyer attend la réponse du locataire.
class BandeauAccords extends StatefulWidget {
  /// Appelé après une réponse (l'accueil se recharge : un bail accepté puis activé y apparaît).
  final VoidCallback? onReponse;
  const BandeauAccords({super.key, this.onReponse});

  @override
  State<BandeauAccords> createState() => _BandeauAccordsState();
}

class _BandeauAccordsState extends State<BandeauAccords> {
  late Future<AccordsLocataire?> _accords = _charger();

  Future<AccordsLocataire?> _charger() async =>
      (await sl<GetAccordsLocataire>()()).fold((_) => null, (a) => a);

  Future<void> _ouvrir() async {
    await ouvrir(context, const AccordsLocatairePage());
    if (!mounted) return;
    setState(() => _accords = _charger());
    widget.onReponse?.call();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AccordsLocataire?>(
    future: _accords,
    builder: (context, s) {
      final a = s.data;
      if (a == null || a.vide) return const SizedBox.shrink();
      final quoi = a.baux.isNotEmpty
          ? (a.baux.length == 1
                ? 'Un bail attend votre accord'
                : '${a.baux.length} baux attendent votre accord')
          : 'Votre bailleur propose un nouveau loyer';
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
        child: Encadre(
          quoi,
          ton: TonStatut.avertissement,
          action: TextButton(onPressed: _ouvrir, child: const Text('Voir')),
        ),
      );
    },
  );
}

/// Ce que le bailleur propose : bail à accepter ou refuser, nouveau loyer.
class AccordsLocatairePage extends StatefulWidget {
  const AccordsLocatairePage({super.key});

  @override
  State<AccordsLocatairePage> createState() => _AccordsLocatairePageState();
}

class _AccordsLocatairePageState extends State<AccordsLocatairePage> {
  late Future<AccordsLocataire> _accords = _charger();

  Future<AccordsLocataire> _charger() async =>
      (await sl<GetAccordsLocataire>()()).ouLeve();

  void _recharger() => setState(() => _accords = _charger());

  Future<void> _repondre(
    String chemin, {
    Map<String, dynamic> corps = const {},
    required String succes,
  }) async {
    final r = await sl<ActionLocataire>()(chemin, corps: corps);
    if (!mounted) return;
    r.fold((f) => afficherErreurApi(context, f), (_) {
      afficherSucces(context, succes);
      _recharger();
    });
  }

  Future<void> _refuser(String chemin, String titre) async {
    final motif = await confirmer(
      context,
      titre: titre,
      message: 'Votre bailleur reçoit votre réponse et son motif.',
      action: 'Refuser',
      danger: true,
      motif: true,
      libelleMotif: 'Pourquoi refusez-vous ?',
      maxMotif: 1000,
    );
    if (motif == null) return;
    await _repondre(
      chemin,
      corps: {'reason': motif},
      succes: 'Réponse envoyée',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const FondMarque(),
      title: const Text('À accepter'),
    ),
    body: FutureBuilder<AccordsLocataire>(
      future: _accords,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return VueChargement(failure: s.error, onReessayer: _recharger);
        }
        final a = s.data!;
        if (a.vide) {
          return const Vide(
            'Rien à accepter pour le moment.',
            icone: Icons.task_alt,
            detail: 'Les baux et changements de loyer proposés par votre bailleur apparaîtront ici.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _recharger(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              for (final b in a.baux) ...[
                _CarteBail(
                  b: b,
                  onAccepter: () => _accepterBail(b),
                  onRefuser: () =>
                      _refuser('baux/${b.id}/refuser', 'Refuser le bail'),
                ),
                const SizedBox(height: AppTheme.espaceLg),
              ],
              for (final p in a.avenants) ...[
                _CarteAvenant(
                  p: p,
                  onAccepter: () => _accepterAvenant(p),
                  onRefuser: () => _refuser(
                    'avenants/${p.avenant.id}/refuser',
                    'Refuser le nouveau loyer',
                  ),
                ),
                const SizedBox(height: AppTheme.espaceLg),
              ],
            ],
          ),
        );
      },
    ),
  );

  Future<void> _accepterBail(BailPropose b) async {
    final ok = await confirmer(
      context,
      titre: 'Accepter le bail',
      message:
          'Vous acceptez ce bail : loyer de ${montant(b.loyer)}, charges de ${montant(b.charges)}, '
          'caution de ${montant(b.caution)}, à partir du ${date(b.debut)}. '
          'Votre bailleur pourra ensuite l’activer.',
      action: 'J’accepte',
    );
    if (ok == null) return;
    await _repondre('baux/${b.id}/accepter', succes: 'Bail accepté');
  }

  Future<void> _accepterAvenant(AvenantPropose p) async {
    final a = p.avenant;
    final ok = await confirmer(
      context,
      titre: 'Accepter le nouveau loyer',
      message:
          'À partir du ${date(a.dateEffet)}, vous paierez ${montant(a.total)} par mois '
          '(au lieu de ${montant(a.totalAvant)}).',
      action: 'J’accepte',
    );
    if (ok == null) return;
    await _repondre(
      'avenants/${a.id}/accepter',
      succes: 'Nouveau loyer accepté',
    );
  }
}

class _Boutons extends StatelessWidget {
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;
  const _Boutons({required this.onAccepter, required this.onRefuser});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppTheme.espaceMd),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onRefuser,
            child: const Text('Refuser'),
          ),
        ),
        const SizedBox(width: AppTheme.espaceMd),
        Expanded(
          child: FilledButton(
            onPressed: onAccepter,
            child: const Text('Accepter'),
          ),
        ),
      ],
    ),
  );
}

class _CarteBail extends StatelessWidget {
  final BailPropose b;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;
  const _CarteBail({
    required this.b,
    required this.onAccepter,
    required this.onRefuser,
  });

  @override
  Widget build(BuildContext context) {
    final contrat = b.contratDocumentId;
    return Section(
      titre: 'Bail proposé${b.reference == null ? '' : ' · ${b.reference}'}',
      children: [
        Text(
          b.logement,
          style: TextStyle(
            color: context.palette.texte,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (b.adresse != null && b.adresse!.isNotEmpty)
          Text(
            b.adresse!,
            style: TextStyle(color: context.palette.texteSecondaire),
          ),
        const SizedBox(height: AppTheme.espaceMd),
        if (b.bailleur != null) Ligne('Bailleur', b.bailleur),
        Ligne('Type', refs.libelle('type_bail', b.typeBail)),
        Ligne(
          'Durée',
          'à partir du ${date(b.debut)}${b.fin == null ? ', sans date de fin' : ' jusqu’au ${date(b.fin)}'}',
        ),
        Ligne(
          'Loyer',
          '${montant(b.loyer)} · ${refs.libelle('periodicite', b.periodicite)}',
        ),
        Ligne('Charges', montant(b.charges)),
        Ligne('Caution', montant(b.caution)),
        if (b.jourEcheance != null)
          Ligne('À payer', 'le ${b.jourEcheance} de chaque mois'),
        if (b.preavisMois != null) Ligne('Préavis', '${b.preavisMois} mois'),
        if (b.revisionLoyer != null && b.revisionLoyer!.isNotEmpty)
          Ligne('Révision du loyer', b.revisionLoyer),
        if (b.conditionsParticulieres != null &&
            b.conditionsParticulieres!.isNotEmpty)
          Ligne('Conditions particulières', b.conditionsParticulieres),
        if (contrat != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.espaceSm),
            child: TextButton.icon(
              onPressed: () => ouvrirPdf(
                context,
                () => sl<TelechargerDocument>()(contrat),
                'contrat-${b.reference ?? 'bail'}.pdf',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Lire le contrat'),
            ),
          ),
        _Boutons(onAccepter: onAccepter, onRefuser: onRefuser),
      ],
    );
  }
}

class _CarteAvenant extends StatelessWidget {
  final AvenantPropose p;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;
  const _CarteAvenant({
    required this.p,
    required this.onAccepter,
    required this.onRefuser,
  });

  @override
  Widget build(BuildContext context) {
    final a = p.avenant;
    return Section(
      titre: 'Nouveau loyer proposé',
      children: [
        Text(
          p.logement,
          style: TextStyle(color: context.palette.texteSecondaire),
        ),
        const SizedBox(height: AppTheme.espaceMd),
        Ligne('Aujourd’hui', '${montant(a.totalAvant)} par mois'),
        Ligne('Proposé', '${montant(a.total)} par mois'),
        if (a.charges != a.chargesAvant)
          Ligne(
            'Dont charges',
            '${montant(a.chargesAvant)} → ${montant(a.charges)}',
          ),
        Ligne('À partir du', date(a.dateEffet)),
        if (a.motif != null && a.motif!.isNotEmpty) Ligne('Motif', a.motif),
        const SizedBox(height: AppTheme.espaceSm),
        Text(
          'Si vous refusez, votre loyer actuel reste en vigueur.',
          style: TextStyle(
            color: context.palette.texteSecondaire,
            fontSize: 13,
          ),
        ),
        _Boutons(onAccepter: onAccepter, onRefuser: onRefuser),
      ],
    );
  }
}
