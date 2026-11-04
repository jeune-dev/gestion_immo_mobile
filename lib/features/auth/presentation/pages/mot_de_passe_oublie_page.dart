import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Délai avant de pouvoir redemander un code (le serveur limite aussi).
const _delaiRenvoi = Duration(seconds: 60);

/// Mot de passe oublié en trois étapes (comme Yobante) : identifiant → code
/// reçu par e-mail (vérifié) → nouveau mot de passe. Le serveur répond de la
/// même façon que le compte existe ou non.
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
  Timer? _minuterie;
  int _attente = 0;

  void _demarrerAttente() {
    _minuterie?.cancel();
    setState(() => _attente = _delaiRenvoi.inSeconds);
    _minuterie = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _attente <= 1) {
        t.cancel();
        if (mounted) setState(() => _attente = 0);
        return;
      }
      setState(() => _attente--);
    });
  }

  void _valider(EtapeReinitialisation etape) {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<MotDePasseOublieBloc>();
    switch (etape) {
      case EtapeReinitialisation.identifiant:
        bloc.add(EnvoyerCodeEvent(_identifiant.text));
      case EtapeReinitialisation.code:
        bloc.add(
          VerifierCodeEvent(
            IdentifiantValidator.codeReinitialisation(_code.text).valeur!,
          ),
        );
      case EtapeReinitialisation.motDePasse:
        bloc.add(
          ReinitialiserMotDePasseEvent(
            motDePasse: _mdp.text,
            confirmation: _confirmation.text,
          ),
        );
      case EtapeReinitialisation.terminee:
        break;
    }
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _identifiant.dispose();
    _code.dispose();
    _mdp.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  static const _titres = {
    EtapeReinitialisation.identifiant: (
      'Mot de passe oublié',
      'Indiquez votre téléphone ou votre e-mail : nous vous envoyons un code par e-mail.',
    ),
    EtapeReinitialisation.code: (
      'Vérifiez vos e-mails',
      'Si un compte correspond, un code de 8 caractères vient d’être envoyé à son adresse e-mail. Il est valable 15 minutes ; pensez à regarder les indésirables.',
    ),
    EtapeReinitialisation.motDePasse: (
      'Nouveau mot de passe',
      'Choisissez votre nouveau mot de passe.',
    ),
    EtapeReinitialisation.terminee: ('Mot de passe modifié', null),
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MotDePasseOublieBloc, MotDePasseOublieState>(
      listener: (context, state) {
        if (state is CodeEnvoye) {
          _code.clear();
          _demarrerAttente();
        } else if (state is MotDePasseReinitialise) {
          afficherSucces(context, 'Mot de passe modifié : connectez-vous.');
          context.go(AppRouter.connexion);
        }
      },
      builder: (context, state) {
        final etape = state.etape;
        final enCours = state is MotDePasseOublieLoading;
        final (titre, sousTitre) = _titres[etape]!;
        return AuthCadre(
          retour: true,
          titre: titre,
          sousTitre: sousTitre,
          children: [
            _Etapes(etape),
            const SizedBox(height: AppTheme.espaceLg),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state is MotDePasseOublieError) ...[
                    Encadre(state.message, ton: TonStatut.danger),
                    const SizedBox(height: AppTheme.espaceLg),
                  ],
                  if (etape == EtapeReinitialisation.identifiant)
                    TextFormField(
                      controller: _identifiant,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone ou e-mail',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                    ),
                  if (etape == EtapeReinitialisation.code)
                    TextFormField(
                      controller: _code,
                      autofocus: true,
                      maxLength: 9,
                      textCapitalization: TextCapitalization.characters,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9 ]'),
                        ),
                      ],
                      style: const TextStyle(letterSpacing: 4),
                      decoration: const InputDecoration(
                        labelText: 'Code reçu',
                        hintText: 'XXXXXXXX',
                      ),
                      validator: (v) =>
                          IdentifiantValidator.codeReinitialisation(v)
                              .erreurFormulaire,
                    ),
                  if (etape == EtapeReinitialisation.motDePasse) ...[
                    ChampMotDePasse(
                      controleur: _mdp,
                      libelle: 'Nouveau mot de passe',
                      nouveau: true,
                      validator: (v) =>
                          IdentifiantValidator.motDePasse(v).erreurFormulaire,
                    ),
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
                    onPressed: enCours ? null : () => _valider(etape),
                    child: Text(switch (etape) {
                      EtapeReinitialisation.identifiant => 'Recevoir un code',
                      EtapeReinitialisation.code => 'Vérifier le code',
                      _ => 'Changer mon mot de passe',
                    }),
                  ),
                  if (etape == EtapeReinitialisation.code)
                    TextButton(
                      onPressed: enCours || _attente > 0
                          ? null
                          : () => context.read<MotDePasseOublieBloc>().add(
                              RenvoyerCodeEvent(),
                            ),
                      child: Text(
                        _attente > 0
                            ? 'Renvoyer le code ($_attente s)'
                            : 'Renvoyer le code',
                      ),
                    ),
                  if (etape != EtapeReinitialisation.identifiant)
                    TextButton(
                      onPressed: enCours
                          ? null
                          : () {
                              _identifiant.text = state.identifiant;
                              context.read<MotDePasseOublieBloc>().add(
                                RecommencerReinitialisation(),
                              );
                            },
                      child: const Text('Changer de téléphone ou d’e-mail'),
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

/// Indicateur « étape n sur 3 ».
class _Etapes extends StatelessWidget {
  final EtapeReinitialisation etape;
  const _Etapes(this.etape);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final index = etape.index.clamp(0, 2);
    return Semantics(
      label: 'Étape ${index + 1} sur 3',
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= index ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
