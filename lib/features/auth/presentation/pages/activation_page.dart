import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';

/// Activation du compte locataire (§ 5 option B) : code d'invitation à 8 chiffres
/// reçu du propriétaire, téléphone et mot de passe.
class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _telephone = TextEditingController();
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  void _valider() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          ActivationDemandee({
            'code': _code.text.trim(),
            'phone': _telephone.text.trim(),
            'password': _mdp.text,
            'password_confirmation': _confirmation.text,
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: true,
      titre: 'Activer mon compte locataire',
      sousTitre:
          "Saisissez le code d'invitation reçu de votre propriétaire et le numéro de téléphone qu'il a enregistré.",
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ErreurAuth(),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration:
                    const InputDecoration(labelText: "Code d'invitation"),
                validator: (v) => RegExp(r'^\d{8}$').hasMatch((v ?? '').trim())
                    ? null
                    : '8 chiffres',
              ),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                    labelText: 'Téléphone', hintText: '77 123 45 67'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: AppTheme.espaceLg),
              ChampMotDePasse(
                  controleur: _mdp,
                  libelle: 'Choisissez un mot de passe',
                  nouveau: true,
                  validator: validerMotDePasse),
              const SizedBox(height: AppTheme.espaceLg),
              ChampMotDePasse(
                controleur: _confirmation,
                libelle: 'Confirmation',
                validator: (v) =>
                    v != _mdp.text ? 'Les mots de passe diffèrent' : null,
              ),
              const SizedBox(height: AppTheme.espaceXl),
              BoutonAuth(libelle: 'Activer mon compte', onPressed: _valider),
            ],
          ),
        ),
      ],
    );
  }
}
