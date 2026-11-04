import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/auth_cadre.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/erreur_auth.dart';

enum _TypeIdentifiant { email, telephone }

/// Connexion (§ 5) par e-mail ou téléphone, puis code de double authentification si actif.
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  _TypeIdentifiant _type = _TypeIdentifiant.email;
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();
  bool _secours = false;

  @override
  void initState() {
    super.initState();
    effacerErreurAuth(context);
  }

  @override
  void dispose() {
    _email.dispose();
    _telephone.dispose();
    _motDePasse.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Valeur normalisée du champ affiché (le formulaire vient de la valider).
  String _identifiantSaisi() => _type == _TypeIdentifiant.email
      ? IdentifiantValidator.email(_email.text).valeur!.toLowerCase()
      : IdentifiantValidator.telephone(_telephone.text).valeur!;

  void _choisir(_TypeIdentifiant type) {
    if (type == _type) return;
    effacerErreurAuth(context);
    setState(() => _type = type);
  }

  void _envoyer({required bool mfa}) {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    if (!mfa) {
      bloc.add(
        ConnexionDemandee(
          identifiant: _identifiantSaisi(),
          motDePasse: _motDePasse.text,
        ),
      );
    } else {
      final code = _code.text.trim();
      bloc.add(
        _secours ? MfaSoumise(codeSecours: code) : MfaSoumise(code: code),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mfa = context.select((AuthBloc b) => b.state.mfaJeton != null);
    return AuthCadre(
      titre: mfa ? 'Code de vérification' : 'Connexion',
      sousTitre: mfa
          ? (_secours
                ? 'Saisissez un de vos codes de secours.'
                : "Saisissez le code à 6 chiffres de votre application d'authentification.")
          : 'Accédez à vos biens ou à votre logement.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ErreurAuth(),
                if (!mfa) ...[
                  _ChoixIdentifiant(type: _type, onChoix: _choisir),
                  const SizedBox(height: AppTheme.espaceMd),
                  LibelleChamp(
                    _type == _TypeIdentifiant.email ? 'E-mail' : 'Téléphone',
                  ),
                  if (_type == _TypeIdentifiant.email)
                    TextFormField(
                      key: const ValueKey('connexion-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: const InputDecoration(
                        hintText: 'exemple@email.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => IdentifiantValidator.email(
                        v,
                        obligatoire: true,
                      ).erreurFormulaire,
                    )
                  else
                    TextFormField(
                      key: const ValueKey('connexion-telephone'),
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.telephoneNumber,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s+().-]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: '77 123 45 67',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => IdentifiantValidator.telephone(
                        v,
                        obligatoire: true,
                      ).erreurFormulaire,
                    ),
                  const SizedBox(height: AppTheme.espaceMd),
                  const LibelleChamp('Mot de passe'),
                  ChampMotDePasse(
                    controleur: _motDePasse,
                    indication: 'Votre mot de passe',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRouter.motDePasseOublie),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                ] else
                  TextFormField(
                    controller: _code,
                    autofocus: true,
                    keyboardType: _secours
                        ? TextInputType.text
                        : TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: _secours ? 20 : 6,
                    decoration: InputDecoration(
                      labelText: _secours
                          ? 'Code de secours'
                          : 'Code à 6 chiffres',
                    ),
                    validator: (v) => _secours
                        ? ((v ?? '').trim().isEmpty ? 'Obligatoire' : null)
                        : IdentifiantValidator.code(
                            v,
                            longueur: 6,
                          ).erreurFormulaire,
                  ),
                const SizedBox(height: AppTheme.espaceSm),
                BoutonAuth(
                  libelle: mfa ? 'Valider' : 'Se connecter',
                  onPressed: () => _envoyer(mfa: mfa),
                ),
                if (mfa) ...[
                  TextButton(
                    onPressed: () => setState(() {
                      _secours = !_secours;
                      _code.clear();
                    }),
                    child: Text(
                      _secours
                          ? "Utiliser l'application"
                          : 'Utiliser un code de secours',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<AuthBloc>().add(MfaAbandonnee()),
                    child: const Text('Retour'),
                  ),
                ] else ...[
                  const SizedBox(height: AppTheme.espaceLg),
                  const _SeparateurAcces(),
                  const SizedBox(height: AppTheme.espaceMd),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ChoixAcces(
                            icone: Icons.apartment_outlined,
                            titre: 'Je suis propriétaire',
                            detail: 'Créer mon compte',
                            onTap: () => context.push(AppRouter.inscription),
                          ),
                        ),
                        const SizedBox(width: AppTheme.espaceSm),
                        Expanded(
                          child: _ChoixAcces(
                            icone: Icons.key_outlined,
                            titre: 'Je suis locataire',
                            detail: "J'ai un code d'invitation",
                            onTap: () => context.push(AppRouter.activation),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Choix du mode de connexion : l'onglet actif porte la couleur principale.
class _ChoixIdentifiant extends StatelessWidget {
  final _TypeIdentifiant type;
  final ValueChanged<_TypeIdentifiant> onChoix;
  const _ChoixIdentifiant({required this.type, required this.onChoix});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    Widget onglet(_TypeIdentifiant valeur, String libelle) {
      final actif = valeur == type;
      return Expanded(
        child: Semantics(
          button: true,
          selected: actif,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChoix(valeur),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: actif ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
              ),
              child: Text(
                libelle,
                style: TextStyle(
                  color: actif ? cs.onPrimary : p.texteSecondaire,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.rayon),
      ),
      child: Row(
        children: [
          onglet(_TypeIdentifiant.email, 'E-mail'),
          const SizedBox(width: 4),
          onglet(_TypeIdentifiant.telephone, 'Téléphone'),
        ],
      ),
    );
  }
}

class _SeparateurAcces extends StatelessWidget {
  const _SeparateurAcces();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Flexible(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.espaceMd),
          child: Text(
            'Pas encore de compte ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.texteSecondaire,
              fontSize: 13,
            ),
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

/// Accès pour un nouvel utilisateur : icône, profil, action.
class _ChoixAcces extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;
  final VoidCallback onTap;
  const _ChoixAcces({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = Theme.of(context).colorScheme;
    final rayon = BorderRadius.circular(AppTheme.rayon);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: rayon,
        child: Ink(
          padding: const EdgeInsets.all(AppTheme.espaceMd),
          decoration: BoxDecoration(
            borderRadius: rayon,
            border: Border.all(color: p.bordure),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.primaireTeinte,
                  borderRadius: BorderRadius.circular(AppTheme.rayonPetit),
                ),
                child: Icon(icone, color: cs.primary, size: 20),
              ),
              const SizedBox(height: AppTheme.espaceSm),
              Text(
                titre,
                style: TextStyle(
                  color: p.texte,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(color: p.texteSecondaire, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
