import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/widgets/demarches_locataire.dart';

/// Les trois étapes d'un paiement : choix du moyen, paiement, confirmation.
class EtapesPaiement extends StatelessWidget {
  /// Étape en cours, de 1 à 3.
  final int etape;
  const EtapesPaiement({super.key, required this.etape});

  static const _libelles = ['Moyen', 'Paiement', 'Confirmation'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = context.palette;
    return Row(
      children: [
        for (var i = 0; i < _libelles.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < etape ? cs.primary : p.bordure,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: i < etape ? cs.primary : p.surfaceAlt,
                child: i + 1 < etape
                    ? Icon(Icons.check, size: 15, color: cs.onPrimary)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i < etape ? cs.onPrimary : p.texteSecondaire,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                _libelles[i],
                style: TextStyle(
                  color: i < etape ? p.texte : p.texteSecondaire,
                  fontSize: 11,
                  fontWeight: i + 1 == etape
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Pastille d'un moyen de paiement.
class PastilleMoyen extends StatelessWidget {
  final String? portefeuille;
  final IconData? icone;
  const PastilleMoyen({super.key, this.portefeuille, this.icone});

  @override
  Widget build(BuildContext context) {
    final (couleur, sigle) = switch (portefeuille) {
      'wave' => (const Color(0xFF1DA1E0), 'W'),
      'orange_money' => (const Color(0xFFF26A00), 'OM'),
      _ => (Theme.of(context).colorScheme.primary, ''),
    };
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
      ),
      child: icone != null
          ? Icon(icone, color: Colors.white, size: 22)
          : Text(
              sigle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _TuileMoyen extends StatelessWidget {
  final Widget pastille;
  final String titre;
  final String detail;
  final VoidCallback? onTap;
  const _TuileMoyen({
    required this.pastille,
    required this.titre,
    required this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.espaceSm),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.espaceMd),
              child: Row(
                children: [
                  pastille,
                  const SizedBox(width: AppTheme.espaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          style: TextStyle(
                            color: p.texte,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: TextStyle(
                            color: p.texteSecondaire,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: p.texteDiscret),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Première étape : ce qui est à payer, puis le choix du moyen.
class ChoixPaiement extends StatelessWidget {
  final Echeance echeance;
  final MoyensPaiementLocataire moyens;
  final bool enCours;
  final ValueChanged<String> onPayerEnLigne;
  final ValueChanged<MoyenPreuve> onDeclarer;
  final VoidCallback onContacter;

  const ChoixPaiement({
    super.key,
    required this.echeance,
    required this.moyens,
    required this.enCours,
    required this.onPayerEnLigne,
    required this.onDeclarer,
    required this.onContacter,
  });

  static const _portefeuilles = ['wave', 'orange_money'];

  /// Récapitulatif avant de quitter l'application pour payer.
  Future<void> _confirmer(BuildContext context, String portefeuille) async {
    final nom = refs.libelle('portefeuille', portefeuille);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.espaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirmer le paiement',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.espaceMd),
              Ligne('Échéance', echeance.libelle),
              Ligne('Montant', montant(echeance.reste)),
              Ligne('Bénéficiaire', moyens.beneficiaire),
              Ligne('Moyen', nom),
              const SizedBox(height: AppTheme.espaceSm),
              Text(
                'La page de paiement $nom va s’ouvrir. Validez-y le paiement, puis revenez dans l’application.',
                style: TextStyle(
                  color: ctx.palette.texteSecondaire,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.espaceLg),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Payer ${montant(echeance.reste)}'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) onPayerEnLigne(portefeuille);
  }

  /// Espèces : le locataire signale la remise, le bailleur la confirme.
  Future<void> _declarerEspeces(BuildContext context) async {
    final ok = await declarerEspeces(
      context,
      echeanceId: echeance.id,
      reste: echeance.reste,
      beneficiaire: moyens.beneficiaire,
    );
    if (ok && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final preuves = moyens.preuves;
    final indisponibles = _portefeuilles.where(
      (w) =>
          !moyens.integres.contains(w) &&
          !preuves.any((p) => p.portefeuille == w),
    );
    final aucun = moyens.integres.isEmpty && preuves.isEmpty;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.espaceLg),
      children: [
        CarteMarque(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (echeance.libelle ?? 'Loyer').toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Text(
                montant(echeance.reste),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTheme.espaceSm),
              if (echeance.dateEcheance != null)
                Text(
                  'À payer avant le ${date(echeance.dateEcheance)}',
                  style: const TextStyle(color: Colors.white),
                ),
              if (moyens.beneficiaire != null)
                Text(
                  'Bénéficiaire : ${moyens.beneficiaire}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.espaceXl),
        const EtapesPaiement(etape: 1),
        const SizedBox(height: AppTheme.espaceXl),
        Text(
          'Comment souhaitez-vous payer ?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.espaceMd),
        for (final w in moyens.integres)
          _TuileMoyen(
            pastille: PastilleMoyen(portefeuille: w),
            titre: refs.libelle('portefeuille', w),
            detail: 'Paiement sécurisé, confirmation immédiate',
            onTap: enCours ? null : () => _confirmer(context, w),
          ),
        for (final p in preuves)
          _TuileMoyen(
            pastille: PastilleMoyen(portefeuille: p.portefeuille),
            titre: p.libelle ?? refs.libelle('portefeuille', p.portefeuille),
            detail:
                'Envoyez au ${p.numero ?? ''}, puis déclarez votre paiement',
            onTap: () => onDeclarer(p),
          ),
        if (moyens.especes)
          _TuileMoyen(
            pastille: const PastilleMoyen(icone: Icons.payments_outlined),
            titre: 'Espèces',
            detail: 'Remis en main propre ? Signalez-le à votre propriétaire',
            onTap: () => _declarerEspeces(context),
          ),
        for (final w in indisponibles)
          _TuileMoyen(
            pastille: PastilleMoyen(portefeuille: w),
            titre: refs.libelle('portefeuille', w),
            detail: 'Pas encore activé par votre propriétaire',
          ),
        if (aucun) ...[
          const SizedBox(height: AppTheme.espaceSm),
          OutlinedButton.icon(
            onPressed: onContacter,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contacter mon propriétaire'),
          ),
        ],
      ],
    );
  }
}
