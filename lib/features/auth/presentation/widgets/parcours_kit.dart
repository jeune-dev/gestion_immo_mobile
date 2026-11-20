import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Briques communes du parcours d'inscription et d'activation : en-tête de
/// marque, progression, boutons, cases de code, règles du mot de passe.
///
/// Un seul endroit à toucher pour faire évoluer la charte de ce parcours.
/// L'ossature reprend celle de la connexion ([AuthCadre]) : bandeau marine en
/// haut, feuille blanche posée à cheval dessus, contenu qui défile d'un seul
/// tenant — bouton compris, pour que le clavier ouvert ne vienne jamais
/// écraser le champ qu'on remplit.

/// Progression : des segments et « ÉTAPE 2 SUR 5 · Contact ».
class EtapesParcours extends StatelessWidget {
  /// Numéro de l'étape en cours, à partir de 1.
  final int courante;
  final List<String> etapes;

  const EtapesParcours({
    super.key,
    required this.courante,
    required this.etapes,
  });

  @override
  Widget build(BuildContext context) {
    final n = courante.clamp(1, etapes.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 1; i <= etapes.length; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  decoration: BoxDecoration(
                    // En cours : vert. Franchie : blanc. À venir : blanc effacé.
                    color: i == n
                        ? AppColors.vertLogo
                        : i < n
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (i < etapes.length) const SizedBox(width: 5),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            children: [
              TextSpan(
                text: 'ÉTAPE $n SUR ${etapes.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' · ${etapes[n - 1]}'),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Ossature d'un écran du parcours : en-tête marine (retour, progression,
/// pictogramme, titre), puis la carte blanche et ce qui vient dessous.
class CadreParcours extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final IconData icone;

  /// Progression ; sans [etapes], l'en-tête n'en montre pas.
  final int etape;
  final List<String> etapes;

  /// Retour ; sans lui, la page précédente s'il y en a une.
  final VoidCallback? onRetour;

  /// Contenu de la carte blanche.
  final List<Widget> carte;

  /// Posé sous la carte (lien « Se connecter », mentions…).
  final List<Widget> apres;

  const CadreParcours({
    super.key,
    required this.titre,
    required this.icone,
    required this.carte,
    this.sousTitre,
    this.etape = 0,
    this.etapes = const [],
    this.onRetour,
    this.apres = const [],
  });

  /// De combien la carte mord sur l'en-tête.
  static const _chevauchement = 30.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final peutRevenir = onRetour != null || Navigator.of(context).canPop();
    return GestureDetector(
      // Toucher à côté d'un champ ferme le clavier.
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: p.fond,
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                FondMarque(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.espaceSm,
                        AppTheme.espaceXs,
                        AppTheme.espaceXl,
                        _chevauchement + AppTheme.espaceXl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (peutRevenir)
                                IconButton(
                                  tooltip: 'Retour',
                                  color: Colors.white,
                                  icon: const Icon(Icons.arrow_back, size: 22),
                                  onPressed:
                                      onRetour ??
                                      () => Navigator.of(context).maybePop(),
                                )
                              else
                                const SizedBox(width: AppTheme.espaceLg),
                              if (etapes.isNotEmpty)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: EtapesParcours(
                                      courante: etape,
                                      etapes: etapes,
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                            ],
                          ),
                          const SizedBox(height: AppTheme.espaceMd),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppTheme.espaceLg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Pictogramme(icone),
                                const SizedBox(height: AppTheme.espaceLg),
                                Text(
                                  titre,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                if (sousTitre != null) ...[
                                  const SizedBox(height: AppTheme.espaceXs),
                                  Text(
                                    sousTitre!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -_chevauchement),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.espaceLg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CarteParcours(enfants: carte),
                            ...apres,
                            SizedBox(
                              height:
                                  MediaQuery.paddingOf(context).bottom +
                                  AppTheme.espaceLg,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte blanche du parcours.
class CarteParcours extends StatelessWidget {
  final List<Widget> enfants;
  const CarteParcours({super.key, required this.enfants});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.espaceLg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.rayonCarte),
        border: Border.all(color: context.palette.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: enfants,
      ),
    );
  }
}

class _Pictogramme extends StatelessWidget {
  final IconData icone;
  const _Pictogramme(this.icone);

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.rayon),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: Icon(icone, color: AppColors.vertLogo, size: 24),
  );
}

/// Bouton principal d'une étape, avec son état d'attente.
class BoutonParcours extends StatelessWidget {
  final String libelle;
  final VoidCallback? onPressed;
  final bool enCours;
  final IconData? icone;

  const BoutonParcours({
    super.key,
    required this.libelle,
    this.onPressed,
    this.enCours = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: enCours ? null : onPressed,
    child: enCours
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Un libellé long rétrécit au lieu de déborder du bouton.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(libelle, maxLines: 1),
                ),
              ),
              if (icone != null) ...[
                const SizedBox(width: AppTheme.espaceSm),
                Icon(icone, size: 18),
              ],
            ],
          ),
  );
}

/// « Déjà un compte ? Se connecter », sous la carte.
class LienConnexion extends StatelessWidget {
  final VoidCallback onTap;
  final String question;
  final String action;

  const LienConnexion({
    super.key,
    required this.onTap,
    this.question = 'Déjà un compte ?',
    this.action = 'Se connecter',
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppTheme.espaceSm),
    child: Center(
      child: TextButton(
        onPressed: onTap,
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 13.5,
              color: context.palette.texteSecondaire,
            ),
            children: [
              TextSpan(text: '$question '),
              TextSpan(
                text: action,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Bandeau d'erreur d'une étape (erreur locale, hors AuthBloc).
class BandeauErreur extends StatelessWidget {
  final String? message;
  const BandeauErreur(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.espaceLg),
      padding: const EdgeInsets.all(AppTheme.espaceMd),
      decoration: BoxDecoration(
        color: p.dangerFond,
        borderRadius: BorderRadius.circular(AppTheme.rayon),
        border: Border.all(color: p.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: p.danger, size: 18),
          const SizedBox(width: AppTheme.espaceSm),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(fontSize: 13, color: p.danger, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Saisie d'un code chiffre par chiffre, une case par chiffre.
///
/// La case suivante prend le relais toute seule, « retour » dans une case vide
/// remonte à la précédente et l'efface — sans quoi corriger un chiffre
/// obligerait à tout reprendre — et coller le code entier depuis l'e-mail
/// remplit toutes les cases d'un coup.
class CasesCode extends StatefulWidget {
  final int longueur;

  /// Appelée à chaque changement, avec le code complet (ou partiel).
  final ValueChanged<String> onChange;

  /// Appelée dès que les [longueur] chiffres sont saisis.
  final ValueChanged<String>? onComplet;
  final bool autofocus;

  const CasesCode({
    super.key,
    required this.onChange,
    this.longueur = 6,
    this.onComplet,
    this.autofocus = true,
  });

  @override
  State<CasesCode> createState() => _CasesCodeState();
}

class _CasesCodeState extends State<CasesCode> {
  late final List<TextEditingController> _champs;
  late final List<FocusNode> _noeuds;
  late final List<FocusNode> _touches;

  @override
  void initState() {
    super.initState();
    _champs = List.generate(widget.longueur, (_) => TextEditingController());
    _noeuds = List.generate(widget.longueur, (_) => FocusNode());
    _touches = List.generate(widget.longueur, (_) => FocusNode());
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _noeuds.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _champs) {
      c.dispose();
    }
    for (final n in [..._noeuds, ..._touches]) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _champs.map((c) => c.text).join();

  void _prevenir() {
    final code = _code;
    widget.onChange(code);
    if (code.length == widget.longueur) {
      FocusManager.instance.primaryFocus?.unfocus();
      widget.onComplet?.call(code);
    }
  }

  void _saisie(int index, String valeur) {
    // Collage du code entier (depuis l'e-mail, ou remplissage automatique).
    if (valeur.length > 1) {
      final chiffres = valeur.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.longueur; i++) {
        _champs[i].text = i < chiffres.length ? chiffres[i] : '';
      }
      setState(() {});
      _prevenir();
      return;
    }
    if (valeur.isNotEmpty && index < widget.longueur - 1) {
      _noeuds[index + 1].requestFocus();
    }
    setState(() {});
    _prevenir();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < widget.longueur; i++) ...[
          Expanded(
            child: SizedBox(
              height: 52,
              child: KeyboardListener(
                focusNode: _touches[i],
                onKeyEvent: (evenement) {
                  if (evenement is KeyDownEvent &&
                      evenement.logicalKey == LogicalKeyboardKey.backspace &&
                      _champs[i].text.isEmpty &&
                      i > 0) {
                    _champs[i - 1].clear();
                    _noeuds[i - 1].requestFocus();
                    setState(() {});
                    _prevenir();
                  }
                },
                child: TextField(
                  controller: _champs[i],
                  focusNode: _noeuds[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  // Une case n'accepte qu'un chiffre, mais on laisse passer un
                  // collage plus long : il est réparti sur toutes les cases.
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.texte,
                  ),
                  onChanged: (v) => _saisie(i, v),
                  onTap: () => _champs[i].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _champs[i].text.length,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _champs[i].text.isEmpty
                        ? p.surfaceAlt
                        : p.primaireTeinte,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rayon),
                      borderSide: BorderSide(
                        color: _champs[i].text.isEmpty
                            ? p.bordureChamp
                            : cs.primary,
                        width: 1.4,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rayon),
                      borderSide: BorderSide(color: cs.secondary, width: 1.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i < widget.longueur - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Les quatre règles du mot de passe, cochées au fil de la saisie.
///
/// Le serveur ne signale qu'une règle manquante à la fois : la liste les
/// montre toutes, et chacune se coche dès qu'elle est respectée.
class ReglesMotDePasse extends StatelessWidget {
  final TextEditingController controleur;
  const ReglesMotDePasse({super.key, required this.controleur});

  /// Les règles et leur état, dans l'ordre d'affichage.
  static List<(String, bool)> regles(String mdp) => [
    ('8 caractères', mdp.length >= 8),
    ('Une majuscule', mdp.contains(RegExp('[A-Z]'))),
    ('Une minuscule', mdp.contains(RegExp('[a-z]'))),
    ('Un chiffre', mdp.contains(RegExp(r'\d'))),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controleur,
      builder: (_, valeur, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (texte, ok) in regles(valeur.text))
            Semantics(
              label: '$texte : ${ok ? 'respecté' : 'à respecter'}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(top: AppTheme.espaceSm),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ok ? p.succes : Colors.transparent,
                        border: Border.all(
                          color: ok ? p.succes : p.bordureForte,
                          width: 1.6,
                        ),
                      ),
                      child: ok
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppTheme.espaceSm),
                    Text(
                      texte,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ok ? p.texte : p.texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
