import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session_cubit.dart';
import '../../core/widgets/base.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import 'auth_cadre.dart';

/// Inscription d'un propriétaire (§ 5) : crée son espace avec la période d'essai.
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _form = GlobalKey<FormState>();
  final _c = {for (final k in ['first_name', 'last_name', 'phone', 'email', 'company_name', 'city']) k: TextEditingController()};
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await context.read<SessionCubit>().inscrire({
        for (final e in _c.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
        'password': _mdp.text,
        'password_confirmation': _confirmation.text,
      });
    } on ApiException catch (e) {
      setState(() => _erreur = e.messageComplet);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Widget _champ(String cle, String libelle, {bool obligatoire = true, TextInputType? clavier, List<String>? autofill}) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
        child: TextFormField(
          controller: _c[cle],
          keyboardType: clavier,
          autofillHints: autofill,
          textCapitalization: clavier == null ? TextCapitalization.words : TextCapitalization.none,
          decoration: InputDecoration(labelText: '$libelle${obligatoire ? ' *' : ''}'),
          validator: (v) => obligatoire && (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AuthCadre(
      retour: true,
      titre: 'Créer mon compte',
      sousTitre: "Propriétaire : gérez immeubles, loyers et travaux. Période d'essai offerte.",
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_erreur != null) ...[Encadre(_erreur!, ton: TonStatut.danger), const SizedBox(height: AppTheme.espaceLg)],
            _champ('first_name', 'Prénom', autofill: const [AutofillHints.givenName]),
            _champ('last_name', 'Nom', autofill: const [AutofillHints.familyName]),
            _champ('phone', 'Téléphone', clavier: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
            _champ('email', 'E-mail', clavier: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
            _champ('company_name', 'Société (facultatif)', obligatoire: false),
            _champ('city', 'Ville', obligatoire: false),
            ChampMotDePasse(controleur: _mdp, nouveau: true, validator: validerMotDePasse),
            const SizedBox(height: AppTheme.espaceLg),
            ChampMotDePasse(
              controleur: _confirmation,
              libelle: 'Confirmation du mot de passe',
              validator: (v) => v != _mdp.text ? 'Les mots de passe diffèrent' : null,
            ),
            const SizedBox(height: AppTheme.espaceXl),
            FilledButton(
              onPressed: _envoi ? null : _valider,
              child: _envoi
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Créer mon compte'),
            ),
          ]),
        ),
      ],
    );
  }
}
