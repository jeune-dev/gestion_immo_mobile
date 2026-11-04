import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';

/// Cadre des écrans d'authentification : marque, titre, contenu défilant.
class AuthCadre extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final List<Widget> children;
  final bool retour;

  const AuthCadre({
    super.key,
    required this.titre,
    this.sousTitre,
    required this.children,
    this.retour = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final compact = retour || MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: cs.surface,
        extendBodyBehindAppBar: true,
        appBar: retour
            ? AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête fixe : seul le formulaire défile, rien ne passe sous la
            // barre d'état. Réduit au nom sur les écrans empilés (formulaires
            // longs) et quand le clavier est ouvert.
            FondMarque(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.espaceXl,
                      haut + (compact ? AppTheme.espaceSm : AppTheme.espaceLg),
                      AppTheme.espaceXl,
                      AppTheme.rayonFeuille + AppTheme.espaceLg,
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _EnTeteMarque(compact: compact),
                    ),
                  ),
                  // Haut arrondi de la feuille, posé sur l'en-tête.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: AppTheme.rayonFeuille,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.rayonFeuille),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: cs.surface,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.espaceXl,
                    AppTheme.espaceXs,
                    AppTheme.espaceXl,
                    AppTheme.espaceLg + bas,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            titre,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (sousTitre != null) ...[
                            const SizedBox(height: AppTheme.espaceXs),
                            Text(
                              sousTitre!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.texteSecondaire,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppTheme.espaceXl),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marque de l'en-tête : logo sur pastille blanche, nom, signature.
class _EnTeteMarque extends StatelessWidget {
  final bool compact;
  const _EnTeteMarque({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PastilleLogo(
            rayon: AppTheme.rayonPetit,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: const LogoKerimmo(largeur: 62),
          ),
          const SizedBox(width: AppTheme.espaceSm),
          const NomKerimmo(taille: 24, surFonce: true),
        ],
      );
    }
    return Column(
      children: [
        _PastilleLogo(
          rayon: AppTheme.rayonFeuille,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Image.asset(
            'assets/images/logo_kerimmo.png',
            width: 176,
            semanticLabel: 'Kërimmo',
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: AppTheme.espaceMd),
        const Text(
          'Gérez, suivez, valorisez votre patrimoine',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PastilleLogo extends StatelessWidget {
  final double rayon;
  final EdgeInsetsGeometry padding;
  final Widget child;
  const _PastilleLogo({
    required this.rayon,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(rayon),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33061730),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class ChampMotDePasse extends StatefulWidget {
  final TextEditingController controleur;
  final String libelle;
  final String? Function(String?)? validator;
  final bool nouveau;
  const ChampMotDePasse({
    super.key,
    required this.controleur,
    this.libelle = 'Mot de passe',
    this.validator,
    this.nouveau = false,
  });

  @override
  State<ChampMotDePasse> createState() => _ChampMotDePasseState();
}

class _ChampMotDePasseState extends State<ChampMotDePasse> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controleur,
      obscureText: !_visible,
      autofillHints: [
        widget.nouveau ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(
        labelText: widget.libelle,
        prefixIcon: const Icon(Icons.lock_outline),
        helperMaxLines: 2,
        helperText: widget.nouveau
            ? '8 caractères, avec majuscule, minuscule et chiffre'
            : null,
        suffixIcon: IconButton(
          tooltip: _visible ? 'Masquer' : 'Afficher',
          icon: Icon(
            _visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator:
          widget.validator ?? (v) => (v ?? '').isEmpty ? 'Obligatoire' : null,
    );
  }
}
