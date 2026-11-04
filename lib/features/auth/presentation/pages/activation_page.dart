import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
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
        'phone': IdentifiantValidator.telephone(_telephone.text).valeur!,
        'password': _mdp.text,
        'password_confirmation': _confirmation.text,
      }),
    );
  }

  @override
  void dispose() {
    _code.dispose();
    _telephone.dispose();
    _mdp.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: true,
      titre: 'Activer mon compte',
      sousTitre: "Entrez le code reçu de votre propriétaire et le téléphone qu'il a enregistré.",
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
                textInputAction: TextInputAction.next,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Code d'invitation",
                  hintText: '8 chiffres',
                  counterText: '',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                validator: (v) =>
                    IdentifiantValidator.code(v, longueur: 8).erreurFormulaire,
              ),
              const SizedBox(height: AppTheme.espaceMd),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s+().-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '77 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => IdentifiantValidator.telephone(
                  v,
                  obligatoire: true,
                ).erreurFormulaire,
              ),
              const SizedBox(height: AppTheme.espaceMd),
              ChampMotDePasse(
                controleur: _mdp,
                libelle: 'Choisissez un mot de passe',
                nouveau: true,
                validator: (v) =>
                    IdentifiantValidator.motDePasse(v).erreurFormulaire,
              ),
              const SizedBox(height: AppTheme.espaceMd),
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
