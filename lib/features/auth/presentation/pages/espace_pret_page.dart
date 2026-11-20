import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/parcours_kit.dart';

/// Fin du parcours : le compte existe, la session est ouverte, et l'écran
/// annonce ce qui vient — sans quoi on serait déposé sans un mot sur un
/// tableau de bord vide.
///
/// Le routeur y conduit tant que [AuthState.nouveauCompte] est vrai ; les deux
/// boutons lèvent cette marque et l'on n'y revient plus.
class EspacePretPage extends StatelessWidget {
  const EspacePretPage({super.key});

  /// Jours restants d'une période d'essai, à partir de sa date de fin.
  /// `null` hors essai, ou si la date est absente ou illisible.
  static int? _joursDEssai(String? statut, String? finPeriode) {
    if (statut != 'essai' || finPeriode == null) return null;
    final fin = DateTime.tryParse(finPeriode);
    if (fin == null) return null;
    final jours = fin.difference(DateTime.now()).inDays + 1;
    return jours > 0 ? jours : null;
  }

  void _entrer(BuildContext context, {String? vers}) {
    context.read<AuthBloc>().add(BienvenueVue());
    if (vers != null) context.go(vers);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final prenom = context.select(
      (AuthBloc b) => b.state.compte?.utilisateur.prenom,
    );
    final abonnement = context.select((AuthBloc b) => b.state.compte?.abonnement);
    final essai = _joursDEssai(abonnement?.statut, abonnement?.finPeriode);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.fond,
        body: SingleChildScrollView(
          child: Column(
            children: [
              FondMarque(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.espaceXl,
                      AppTheme.espaceXl,
                      AppTheme.espaceXl,
                      AppTheme.espaceXl + 30,
                    ),
                    child: Column(
                      children: [
                        const _Pastille(),
                        const SizedBox(height: AppTheme.espaceLg),
                        const Text(
                          'Votre espace est prêt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppTheme.espaceSm),
                        Text(
                          [
                            if (prenom != null && prenom.isNotEmpty)
                              'Bienvenue $prenom.',
                            if (essai != null && essai > 0)
                              'Votre essai de $essai jours commence aujourd’hui.',
                          ].join(' '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.espaceLg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          CarteParcours(
                            enfants: [
                              Text(
                                'Pour démarrer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.texte,
                                ),
                              ),
                              const SizedBox(height: AppTheme.espaceMd),
                              const _Depart(
                                icone: Icons.apartment_rounded,
                                texte: 'Ajouter un immeuble',
                              ),
                              const _Depart(
                                icone: Icons.group_add_rounded,
                                texte: 'Inviter un locataire',
                                vert: true,
                              ),
                              const _Depart(
                                icone: Icons.description_rounded,
                                texte: 'Créer un bail',
                              ),
                              const SizedBox(height: AppTheme.espaceLg),
                              BoutonParcours(
                                libelle: 'Découvrir TerangaLoc',
                                onPressed: () =>
                                    _entrer(context, vers: AppRouter.proprietaire),
                              ),
                              const SizedBox(height: AppTheme.espaceSm),
                              OutlinedButton(
                                onPressed: () =>
                                    _entrer(context, vers: AppRouter.abonnement),
                                child: const Text('Voir les abonnements'),
                              ),
                            ],
                          ),
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
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille();

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: const BoxDecoration(
      color: AppColors.secondaire,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
  );
}

/// Une étape de démarrage : pastille, libellé, chevron.
class _Depart extends StatelessWidget {
  final IconData icone;
  final String texte;
  final bool vert;
  const _Depart({required this.icone, required this.texte, this.vert = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.espaceMd),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: vert ? p.secondaireTeinte : p.primaireTeinte,
              borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
            ),
            child: Icon(
              icone,
              size: 17,
              color: vert ? p.succes : AppColors.marine,
            ),
          ),
          const SizedBox(width: AppTheme.espaceMd),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(fontSize: 13.5, color: p.texte),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: p.texteDiscret),
        ],
      ),
    );
  }
}
