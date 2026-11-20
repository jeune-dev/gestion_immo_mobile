import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/services/premiere_ouverture.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';
import 'package:gestion_immo_mobile/injection_container.dart';

/// Un écran d'accueil : son pictogramme, son titre, son texte.
class _Ecran {
  final IconData icone;
  final String titre;
  final String texte;
  const _Ecran(this.icone, this.titre, this.texte);
}

const List<_Ecran> _ecrans = [
  _Ecran(
    Icons.apartment_rounded,
    'Tous vos biens dans une seule application',
    'Immeubles, appartements, locataires et baux : tout est réuni et à jour.',
  ),
  _Ecran(
    Icons.payments_rounded,
    'Les loyers suivis au jour près',
    'Quittances, retards, encaissements : vous savez qui a payé et qui doit encore.',
  ),
  _Ecran(
    Icons.forum_rounded,
    'Vos locataires vous écrivent ici',
    'Incidents, travaux, documents : chacun suit son logement depuis son espace.',
  ),
];

/// Trois écrans d'accueil, à la toute première ouverture seulement.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _defilement = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Noté dès l'affichage : fermer l'application au milieu des trois écrans
    // ne les fait pas revenir à la prochaine ouverture.
    sl<PremiereOuverture>().marquerVu();
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  void _terminer() => context.go(AppRouter.choixProfil);

  void _suivant() {
    if (_index < _ecrans.length - 1) {
      _defilement.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _terminer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dernier = _index == _ecrans.length - 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.espaceLg,
                  AppTheme.espaceSm,
                  AppTheme.espaceSm,
                  0,
                ),
                child: Row(
                  children: [
                    const LogoTerangaLoc(largeur: 28),
                    const SizedBox(width: AppTheme.espaceSm),
                    const NomTerangaLoc(taille: 19),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: dernier ? 0 : 1,
                      child: TextButton(
                        onPressed: dernier ? null : _terminer,
                        child: const Text('Passer'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _defilement,
                  itemCount: _ecrans.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _Page(ecran: _ecrans[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.espaceXl,
                  AppTheme.espaceSm,
                  AppTheme.espaceXl,
                  AppTheme.espaceLg,
                ),
                child: dernier
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _Points(index: _index)),
                          const SizedBox(height: AppTheme.espaceLg),
                          FilledButton(
                            onPressed: _terminer,
                            child: const Text('Commencer'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _Points(index: _index),
                          const Spacer(),
                          FilledButton(
                            onPressed: _suivant,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.espaceXl,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Suivant'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, size: 19),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              // Rappel discret : on peut entrer sans créer de compte.
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.espaceSm),
                child: TextButton(
                  onPressed: () => context.go(AppRouter.connexion),
                  child: Text(
                    "J'ai déjà un compte",
                    style: TextStyle(color: p.texteSecondaire, fontSize: 13.5),
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

/// Un écran : l'illustration occupe la place disponible, le texte se pose
/// dessous.
class _Page extends StatelessWidget {
  final _Ecran ecran;
  const _Page({required this.ecran});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.espaceXl),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.primaireTeinte,
                    borderRadius: BorderRadius.circular(AppTheme.rayonFeuille),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Icon(
                        ecran.icone,
                        size: 96,
                        color: AppColors.marine,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.espaceXl),
          Text(
            ecran.titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.marine,
            ),
          ),
          const SizedBox(height: AppTheme.espaceMd),
          Text(
            ecran.texte,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: p.texteSecondaire,
            ),
          ),
          const SizedBox(height: AppTheme.espaceLg),
        ],
      ),
    );
  }
}

/// Points de progression : celui de la page en cours s'allonge.
class _Points extends StatelessWidget {
  final int index;
  const _Points({required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_ecrans.length, (i) {
        final actif = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: actif ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: actif ? cs.primary : context.palette.bordureForte,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
