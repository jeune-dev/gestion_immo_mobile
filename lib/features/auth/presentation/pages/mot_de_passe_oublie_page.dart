import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/mot_de_passe_oublie_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/mot_de_passe_oublie_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/mot_de_passe_oublie_state.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';

/// Mot de passe oublié : demande d'un code à 6 chiffres puis nouveau mot de passe.
class MotDePasseOubliePage extends StatelessWidget {
  const MotDePasseOubliePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => di.sl<MotDePasseOublieBloc>(),
        child: const _Formulaire(),
      );
}

class _Formulaire extends StatefulWidget {
  const _Formulaire();

  @override
  State<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends State<_Formulaire> {
  final _form = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _code = TextEditingController();
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();

  void _valider(bool codeEnvoye) {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<MotDePasseOublieBloc>();
    if (!codeEnvoye) {
      bloc.add(EnvoyerCodeEvent(_identifiant.text));
      return;
    }
    bloc.add(ReinitialiserMotDePasseEvent(
      identifiant: _identifiant.text,
      code: _code.text,
      motDePasse: _mdp.text,
      confirmation: _confirmation.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MotDePasseOublieBloc, MotDePasseOublieState>(
      listener: (context, state) {
        if (state is MotDePasseReinitialise) {
          afficherSucces(context, 'Mot de passe modifié : connectez-vous.');
          context.go(AppRouter.connexion);
        }
      },
      builder: (context, state) {
        final codeEnvoye = state.etape != EtapeReinitialisation.identifiant;
        final enCours = state is MotDePasseOublieLoading;
        return AuthCadre(
          retour: true,
          titre: 'Mot de passe oublié',
          sousTitre: codeEnvoye
              ? 'Si un compte correspond, un code à 6 chiffres vient de vous être envoyé.'
              : 'Indiquez votre téléphone ou votre e-mail : nous vous envoyons un code.',
          children: [
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state is MotDePasseOublieError) ...[
                    Encadre(state.message, ton: TonStatut.danger),
                    const SizedBox(height: AppTheme.espaceLg),
                  ],
                  TextFormField(
                    controller: _identifiant,
                    enabled: !codeEnvoye,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Téléphone ou e-mail'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                  ),
                  if (codeEnvoye) ...[
                    const SizedBox(height: AppTheme.espaceLg),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: const InputDecoration(labelText: 'Code reçu'),
                      validator: (v) =>
                          IdentifiantValidator.code(v, longueur: 6)
                              .erreurFormulaire,
                    ),
                    ChampMotDePasse(
                        controleur: _mdp,
                        libelle: 'Nouveau mot de passe',
                        nouveau: true,
                        validator: (v) => IdentifiantValidator.motDePasse(v)
                            .erreurFormulaire),
                    const SizedBox(height: AppTheme.espaceLg),
                    ChampMotDePasse(
                      controleur: _confirmation,
                      libelle: 'Confirmation',
                      validator: (v) =>
                          v != _mdp.text ? 'Les mots de passe diffèrent' : null,
                    ),
                  ],
                  const SizedBox(height: AppTheme.espaceXl),
                  FilledButton(
                    onPressed: enCours ? null : () => _valider(codeEnvoye),
                    child: Text(codeEnvoye
                        ? 'Changer mon mot de passe'
                        : 'Recevoir un code'),
                  ),
                  if (codeEnvoye)
                    TextButton(
                      onPressed: () => context
                          .read<MotDePasseOublieBloc>()
                          .add(RecommencerReinitialisation()),
                      child: const Text('Renvoyer un code'),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
