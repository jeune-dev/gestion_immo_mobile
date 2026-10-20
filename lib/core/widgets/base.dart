import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/errors/messages.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';

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
              libelle: refs.libelle(referentiel, code)),
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
          color: c.fond, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: c.texte),
          const SizedBox(width: 4),
          Text(
            libelle,
            style: TextStyle(
                color: c.texte, fontSize: 12, fontWeight: FontWeight.w600),
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
  Widget build(BuildContext context) => Text(montant(valeur),
      style: (style ?? const TextStyle())
          .merge(chiffresFixes)
          .copyWith(color: couleur));
}

/// Carte de section avec titre facultatif et action à droite.
class Section extends StatelessWidget {
  final String? titre;
  final Widget? action;
  final List<Widget> children;
  final bool padding;

  const Section(
      {super.key,
      this.titre,
      this.action,
      required this.children,
      this.padding = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            padding ? const EdgeInsets.all(AppTheme.espaceLg) : EdgeInsets.zero,
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
                    Expanded(
                        child: Text(titre!,
                            style: Theme.of(context).textTheme.titleMedium)),
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
            child: Text(libelle,
                style: TextStyle(
                    color: context.palette.texteSecondaire, fontSize: 14)),
          ),
          const SizedBox(width: AppTheme.espaceMd),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: widget ??
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
  const Vide(this.message,
      {super.key, this.icone = Icons.inbox_outlined, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.espaceXxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: context.palette.texteDiscret),
          const SizedBox(height: AppTheme.espaceMd),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.texteSecondaire),
          ),
          if (action != null) ...[
            const SizedBox(height: AppTheme.espaceLg),
            action!
          ],
        ],
      ),
    );
  }
}

/// Encadré d'information / d'alerte (texte + icône, jamais la couleur seule).
class Encadre extends StatelessWidget {
  final String texte;
  final TonStatut ton;
  final Widget? action;
  const Encadre(this.texte,
      {super.key, this.ton = TonStatut.info, this.action});

  @override
  Widget build(BuildContext context) {
    final c = couleursDuTon(context, ton);
    return Container(
      padding: const EdgeInsets.all(AppTheme.espaceMd),
      decoration: BoxDecoration(
          color: c.fond, borderRadius: BorderRadius.circular(AppTheme.rayon)),
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
              onPressed: onReessayer, child: const Text('Réessayer')),
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

  const ChiffreCle(
      {super.key,
      required this.libelle,
      required this.valeur,
      this.icone,
      this.ton,
      this.onTap,
      this.sous});

  @override
  Widget build(BuildContext context) {
    final c = ton == null ? null : couleursDuTon(context, ton!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icone != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c?.fond ?? context.palette.primaireTeinte,
                    borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
                  ),
                  child: Icon(icone,
                      size: 18,
                      color: c?.texte ?? Theme.of(context).colorScheme.primary),
                ),
              const SizedBox(height: AppTheme.espaceSm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valeur,
                    style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)
                        .merge(chiffresFixes)),
              ),
              Text(libelle,
                  style: TextStyle(
                      color: context.palette.texteSecondaire, fontSize: 13)),
              if (sous != null)
                Text(sous!,
                    style: TextStyle(
                        color: context.palette.texteDiscret, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau « consultation hors ligne » affiché quand les données viennent du cache.
class BandeauHorsLigne extends StatelessWidget {
  const BandeauHorsLigne({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GetIt.instance<ApiClient>().horsLigne,
      builder: (context, hors, _) => !hors
          ? const SizedBox.shrink()
          : Material(
              color: context.palette.neutreFond,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off,
                        size: 16, color: context.palette.neutre),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Hors ligne : dernières données enregistrées.',
                          style: TextStyle(
                              color: context.palette.neutre, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
