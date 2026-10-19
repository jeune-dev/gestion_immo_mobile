import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Cadre des écrans d'authentification : marque, titre, contenu défilant.
class AuthCadre extends StatelessWidget {
  const AuthCadre({super.key, required this.titre, this.sousTitre, required this.children, this.retour = false});
  final String titre;
  final String? sousTitre;
  final List<Widget> children;
  final bool retour;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: retour ? AppBar(backgroundColor: Colors.transparent, foregroundColor: cs.onSurface) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.espaceXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(AppTheme.rayonCarte)),
                    child: Stack(children: [
                      Center(child: Icon(Icons.home_work_outlined, color: cs.onPrimary)),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(width: 9, height: 9, decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: AppTheme.espaceMd),
                  Text('Gestion Immo', style: Theme.of(context).textTheme.titleMedium),
                ]),
                const SizedBox(height: AppTheme.espaceXl),
                Text(titre, style: Theme.of(context).textTheme.headlineMedium),
                if (sousTitre != null) ...[
                  const SizedBox(height: AppTheme.espaceSm),
                  Text(sousTitre!, style: TextStyle(color: context.palette.texteSecondaire, fontSize: 15)),
                ],
                const SizedBox(height: AppTheme.espaceXl),
                ...children,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Règle de mot de passe de l'API : 8 caractères, une majuscule, une minuscule, un chiffre.
String? validerMotDePasse(String? v) {
  final s = v ?? '';
  if (s.length < 8) return '8 caractères minimum';
  if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(s)) return 'Une majuscule, une minuscule et un chiffre';
  return null;
}

class ChampMotDePasse extends StatefulWidget {
  const ChampMotDePasse({super.key, required this.controleur, this.libelle = 'Mot de passe', this.validator, this.nouveau = false});
  final TextEditingController controleur;
  final String libelle;
  final String? Function(String?)? validator;
  final bool nouveau;

  @override
  State<ChampMotDePasse> createState() => _ChampMotDePasseState();
}

class _ChampMotDePasseState extends State<ChampMotDePasse> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controleur,
      obscureText: !_visible,
      autofillHints: [widget.nouveau ? AutofillHints.newPassword : AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.libelle,
        helperText: widget.nouveau ? '8 caractères, avec majuscule, minuscule et chiffre' : null,
        suffixIcon: IconButton(
          tooltip: _visible ? 'Masquer' : 'Afficher',
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator: widget.validator ?? (v) => (v ?? '').isEmpty ? 'Obligatoire' : null,
    );
  }
}
