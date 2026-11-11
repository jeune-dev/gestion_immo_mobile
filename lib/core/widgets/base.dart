import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/messages.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Style des montants : chiffres à largeur fixe (charte § 2).
const chiffresFixes = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// Badge de statut d'après la charte (§ 5) : couleur selon le code, libellé du référentiel.
class Statut extends StatelessWidget {
  /// Famille de la charte ; `null` = ton neutre (statut hors charte).
  final FamilleStatut? famille;
  final String referentiel;
  final String? code;

  const Statut(this.famille, this.referentiel, this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    if (code == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: refs,
      builder: (context, _) => famille == null
          ? Pastille(refs.libelle(referentiel, code))
          : BadgeStatut(
              famille: famille!,
              code: code!,
              libelle: refs.libelle(referentiel, code),
            ),
    );
  }
}

/// Badge libre (libellé + ton), toujours avec une icône (charte § 4, règle 4).
class Pastille extends StatelessWidget {
  final String libelle;
  final TonStatut ton;
  const Pastille(this.libelle, {super.key, this.ton = TonStatut.neutre});

  @override
  Widget build(BuildContext context) {
    final c = couleursDuTon(context, ton);
    final icone = switch (ton) {
      TonStatut.succes => Icons.check_circle_outline,
      TonStatut.avertissement => Icons.schedule,
      TonStatut.danger => Icons.error_outline,
      TonStatut.info => Icons.info_outline,
      TonStatut.neutre => Icons.circle_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: c.texte),
          const SizedBox(width: 4),
          Text(
            libelle,
            style: TextStyle(
              color: c.texte,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class Montant extends StatelessWidget {
  final num? valeur;
  final TextStyle? style;
  final Color? couleur;
  const Montant(this.valeur, {super.key, this.style, this.couleur});

  @override
  Widget build(BuildContext context) => Text(
    montant(valeur),
    // Couleur du texte principal par défaut (et non le gris hérité du corps).
    style: (style ?? const TextStyle())
        .merge(chiffresFixes)
        .copyWith(color: couleur ?? style?.color ?? context.palette.texte),
  );
}

/// Carte de section avec titre facultatif et action à droite.
class Section extends StatelessWidget {
  final String? titre;
  final Widget? action;
  final List<Widget> children;
  final bool padding;

  const Section({
    super.key,
    this.titre,
    this.action,
    required this.children,
    this.padding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding
            ? const EdgeInsets.all(AppTheme.espaceLg)
            : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titre != null)
              Padding(
                padding: EdgeInsets.only(
                  bottom: AppTheme.espaceMd,
                  left: padding ? 0 : AppTheme.espaceLg,
                  right: padding ? 0 : AppTheme.espaceSm,
                  top: padding ? 0 : AppTheme.espaceMd,
                ),
                child: Row(
                  children: [
                    // Trait d'accent au dégradé vert du logo.
                    Container(
                      width: 4,
                      height: 18,
                      margin: const EdgeInsets.only(right: AppTheme.espaceSm),
                      decoration: BoxDecoration(
                        gradient: AppColors.degradeVert,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        titre!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Ligne « libellé : valeur ».
class Ligne extends StatelessWidget {
  final String libelle;
  final String? valeur;
  final Widget? widget;
  const Ligne(this.libelle, this.valeur, {super.key, this.widget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              libelle,
              style: TextStyle(
                color: context.palette.texteSecondaire,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.espaceMd),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  widget ??
                  Text(
                    valeur == null || valeur!.isEmpty ? '—' : valeur!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500)
                        .merge(chiffresFixes),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class Vide extends StatelessWidget {
  final String message;
  final IconData icone;
  final Widget? action;

  /// Explication sous le message.
  final String? detail;
  const Vide(
    this.message, {
    super.key,
    this.icone = Icons.inbox_outlined,
    this.action,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    // Centré dans l'écran, ou en largeur seulement dans une liste.
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.espaceXxl,
          48,
          AppTheme.espaceXxl,
          AppTheme.espaceXxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pictogramme sur pastille bleu clair : un état vide soigné, pas un trou.
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.palette.primaireTeinte,
                    context.palette.secondaireTeinte,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.espaceLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.texte,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppTheme.espaceXs),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.texteSecondaire,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.espaceLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Encadré d'information / d'alerte (texte + icône, jamais la couleur seule).
class Encadre extends StatelessWidget {
  final String texte;
  final TonStatut ton;
  final Widget? action;
  const Encadre(
    this.texte, {
    super.key,
    this.ton = TonStatut.info,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = couleursDuTon(context, ton);
    return Container(
      padding: const EdgeInsets.all(AppTheme.espaceLg),
      decoration: BoxDecoration(
        color: c.fond,
        borderRadius: BorderRadius.circular(AppTheme.rayon),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ton == TonStatut.danger
                ? Icons.error_outline
                : ton == TonStatut.avertissement
                ? Icons.warning_amber
                : Icons.info_outline,
            size: 20,
            color: c.texte,
          ),
          const SizedBox(width: AppTheme.espaceSm),
          Expanded(
            child: Text(texte, style: TextStyle(color: c.texte)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class VueErreur extends StatelessWidget {
  final Object erreur;
  final VoidCallback? onReessayer;
  const VueErreur(this.erreur, {super.key, this.onReessayer});

  @override
  Widget build(BuildContext context) {
    final e = erreur;
    final reseau = erreurReseau(e);
    return Vide(
      messageErreur(e),
      icone: reseau ? Icons.wifi_off : Icons.error_outline,
      action: onReessayer == null
          ? null
          : OutlinedButton(
              onPressed: onReessayer,
              child: const Text('Réessayer'),
            ),
    );
  }
}

/// Chiffre clé du tableau de bord.
class ChiffreCle extends StatelessWidget {
  final String libelle;
  final String valeur;
  final IconData? icone;
  final TonStatut? ton;
  final VoidCallback? onTap;
  final String? sous;

  const ChiffreCle({
    super.key,
    required this.libelle,
    required this.valeur,
    this.icone,
    this.ton,
    this.onTap,
    this.sous,
  });

  @override
  Widget build(BuildContext context) {
    final c = ton == null ? null : couleursDuTon(context, ton!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icone != null)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c?.fond ?? context.palette.primaireTeinte,
                        borderRadius: BorderRadius.circular(AppTheme.rayon - 2),
                      ),
                      child: Icon(
                        icone,
                        size: 20,
                        color:
                            c?.texte ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: context.palette.texteDiscret,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.espaceMd),
              Text(
                libelle,
                style: TextStyle(
                  color: context.palette.texteSecondaire,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valeur,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ).merge(chiffresFixes).copyWith(color: context.palette.texte),
                ),
              ),
              if (sous != null)
                Text(
                  sous!,
                  style: TextStyle(
                    color: context.palette.texteDiscret,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pictogramme d'une option : icône sur pastille teintée.
class IconeOption extends StatelessWidget {
  final IconData icone;
  final Color? couleur;
  const IconeOption(this.icone, {super.key, this.couleur});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: context.palette.primaireTeinte,
      borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
    ),
    child: Icon(
      icone,
      size: 21,
      color: couleur ?? Theme.of(context).colorScheme.primary,
    ),
  );
}

/// Option d'une liste : pictogramme, titre, précision et flèche.
class TuileOption extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? detail;
  final Widget? fin;
  final VoidCallback? onTap;

  /// Sans marge horizontale, dans une section qui a déjà la sienne.
  final bool sansMarge;
  const TuileOption({
    super.key,
    required this.icone,
    required this.titre,
    this.detail,
    this.fin,
    this.onTap,
    this.sansMarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sansMarge ? 0 : AppTheme.espaceLg,
          vertical: AppTheme.espaceMd,
        ),
        child: Row(
          children: [
            IconeOption(icone),
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
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: TextStyle(color: p.texteSecondaire, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTheme.espaceSm),
            fin ?? Icon(Icons.chevron_right, color: p.texteDiscret),
          ],
        ),
      ),
    );
  }
}

/// Options regroupées sous un petit titre.
class GroupeOptions extends StatelessWidget {
  final String titre;
  final List<Widget> children;
  const GroupeOptions({super.key, required this.titre, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: AppTheme.espaceXs,
          bottom: AppTheme.espaceSm,
        ),
        child: Text(
          titre.toUpperCase(),
          style: TextStyle(
            color: context.palette.texteSecondaire,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 68,
                  endIndent: AppTheme.espaceLg,
                ),
              c,
            ],
          ],
        ),
      ),
    ],
  );
}

/// En-tête d'une fiche : carte de marque avec surtitre, titre et statut.
class EnTeteFiche extends StatelessWidget {
  final String? surtitre;
  final String titre;
  final String? detail;
  final Widget? statut;
  const EnTeteFiche({
    super.key,
    this.surtitre,
    required this.titre,
    this.detail,
    this.statut,
  });

  @override
  Widget build(BuildContext context) => CarteMarque(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (surtitre != null || statut != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.espaceSm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (surtitre ?? '').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                ?statut,
              ],
            ),
          ),
        Text(
          titre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: AppTheme.espaceXs),
          Text(
            detail!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ],
    ),
  );
}
