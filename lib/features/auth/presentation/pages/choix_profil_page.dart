import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/parcours_kit.dart';

enum _Profil { proprietaire, locataire }

/// Premier écran de la création de compte : propriétaire ou locataire.
///
/// Les deux parcours n'ont rien à voir — le propriétaire ouvre un espace et
/// paie un abonnement, le locataire active un espace que son propriétaire a
/// déjà créé pour lui. Les poser côte à côte, en pleine page, évite qu'un
/// locataire s'inscrive comme propriétaire et se retrouve avec un espace vide.
class ChoixProfilPage extends StatefulWidget {
  const ChoixProfilPage({super.key});

  @override
  State<ChoixProfilPage> createState() => _ChoixProfilPageState();
}

class _ChoixProfilPageState extends State<ChoixProfilPage> {
  _Profil _choix = _Profil.proprietaire;

  void _continuer() => context.push(
    _choix == _Profil.proprietaire
        ? AppRouter.inscription
        : AppRouter.activation,
  );

  @override
  Widget build(BuildContext context) {
    return CadreParcours(
      icone: Icons.person_add_alt_1_rounded,
      titre: 'Créer un compte',
      sousTitre: 'Choisissez votre espace.',
      carte: [
        _CarteProfil(
          icone: Icons.apartment_rounded,
          titre: 'Je suis propriétaire',
          texte: 'Gérer mes immeubles, mes baux et mes loyers.',
          atouts: const ["Période d'essai", 'Sans carte bancaire'],
          choisi: _choix == _Profil.proprietaire,
          onTap: () => setState(() => _choix = _Profil.proprietaire),
        ),
        const SizedBox(height: AppTheme.espaceMd),
        _CarteProfil(
          icone: Icons.vpn_key_rounded,
          titre: 'Je suis locataire',
          texte: 'Activer mon espace avec le code de mon propriétaire.',
          atouts: const ['Gratuit', 'Quittances en ligne'],
          choisi: _choix == _Profil.locataire,
          onTap: () => setState(() => _choix = _Profil.locataire),
        ),
        const SizedBox(height: AppTheme.espaceXl),
        BoutonParcours(
          libelle: 'Continuer',
          icone: Icons.arrow_forward,
          onPressed: _continuer,
        ),
      ],
      apres: [
        LienConnexion(onTap: () => context.go(AppRouter.connexion)),
      ],
    );
  }
}

/// Carte à choix unique : fond blanc, et une fois choisie, bordure verte,
/// pastille verte et coche.
class _CarteProfil extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  final List<String> atouts;
  final bool choisi;
  final VoidCallback onTap;

  const _CarteProfil({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.atouts,
    required this.choisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: choisi,
      label: '$titre. $texte',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppTheme.espaceMd + 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.rayon),
            border: Border.all(
              color: choisi ? cs.secondary : p.bordure,
              width: choisi ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: choisi ? p.secondaireTeinte : p.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
                    ),
                    child: Icon(icone, size: 21, color: AppColors.marine),
                  ),
                  const SizedBox(width: AppTheme.espaceMd),
                  Expanded(
                    child: Text(
                      titre,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: p.texte,
                      ),
                    ),
                  ),
                  _Coche(coche: choisi),
                ],
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Text(
                texte,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: p.texteSecondaire,
                ),
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in atouts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: p.fond,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 13,
                            color: choisi ? p.succes : p.texteDiscret,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            a,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.texte,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Coche extends StatelessWidget {
  final bool coche;
  const _Coche({required this.coche});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: coche ? cs.secondary : Colors.transparent,
        border: Border.all(
          color: coche ? cs.secondary : context.palette.bordureForte,
          width: 2,
        ),
      ),
      child: coche
          ? Icon(Icons.check, size: 15, color: cs.onSecondary)
          : null,
    );
  }
}
