import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';

/// Inscription d'un propriétaire (§ 5) : crée son espace avec la période d'essai.
class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _form = GlobalKey<FormState>();
  final _c = {
    for (final k in [
      'first_name',
      'last_name',
      'phone',
      'email',
      'company_name',
      'city'
    ])
      k: TextEditingController(),
  };
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
          InscriptionDemandee({
            for (final e in _c.entries)
              if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
            'password': _mdp.text,
            'password_confirmation': _confirmation.text,
          }),
        );
  }

  Widget _champ(String cle, String libelle,
          {bool obligatoire = true,
          TextInputType? clavier,
          List<String>? autofill}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
        child: TextFormField(
          controller: _c[cle],
          keyboardType: clavier,
          autofillHints: autofill,
          textCapitalization: clavier == null
              ? TextCapitalization.words
              : TextCapitalization.none,
          decoration:
              InputDecoration(labelText: '$libelle${obligatoire ? ' *' : ''}'),
          validator: (v) =>
              obligatoire && (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: true,
      titre: 'Créer mon compte',
      sousTitre:
          "Propriétaire : gérez immeubles, loyers et travaux. Période d'essai offerte.",
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ErreurAuth(),
              _champ('first_name', 'Prénom',
                  autofill: const [AutofillHints.givenName]),
              _champ('last_name', 'Nom',
                  autofill: const [AutofillHints.familyName]),
              _champ('phone', 'Téléphone',
                  clavier: TextInputType.phone,
                  autofill: const [AutofillHints.telephoneNumber]),
              _champ('email', 'E-mail',
                  clavier: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email]),
              _champ('company_name', 'Société (facultatif)',
                  obligatoire: false),
              _champ('city', 'Ville', obligatoire: false),
              ChampMotDePasse(
                  controleur: _mdp,
                  nouveau: true,
                  validator: validerMotDePasse),
              const SizedBox(height: AppTheme.espaceLg),
              ChampMotDePasse(
                controleur: _confirmation,
                libelle: 'Confirmation du mot de passe',
                validator: (v) =>
                    v != _mdp.text ? 'Les mots de passe diffèrent' : null,
              ),
              const SizedBox(height: AppTheme.espaceXl),
              BoutonAuth(libelle: 'Créer mon compte', onPressed: _valider),
            ],
          ),
        ),
      ],
    );
  }
}
