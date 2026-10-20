import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';

/// Cadre des écrans d'authentification : marque, titre, contenu défilant.
class AuthCadre extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final List<Widget> children;
  final bool retour;

  const AuthCadre(
      {super.key,
      required this.titre,
      this.sousTitre,
      required this.children,
      this.retour = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: retour
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: cs.onSurface)
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.espaceXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius:
                                BorderRadius.circular(AppTheme.rayonCarte)),
                        child: Stack(
                          children: [
                            Center(
                                child: Icon(Icons.home_work_outlined,
                                    color: cs.onPrimary)),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                    color: cs.secondary,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.espaceMd),
                      Text('Gestion Immo',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppTheme.espaceXl),
                  Text(titre,
                      style: Theme.of(context).textTheme.headlineMedium),
                  if (sousTitre != null) ...[
                    const SizedBox(height: AppTheme.espaceSm),
                    Text(sousTitre!,
                        style: TextStyle(
                            color: context.palette.texteSecondaire,
                            fontSize: 15)),
                  ],
                  const SizedBox(height: AppTheme.espaceXl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChampMotDePasse extends StatefulWidget {
  final TextEditingController controleur;
  final String libelle;
  final String? Function(String?)? validator;
  final bool nouveau;
  const ChampMotDePasse(
      {super.key,
      required this.controleur,
      this.libelle = 'Mot de passe',
      this.validator,
      this.nouveau = false});

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
      autofillHints: [
        widget.nouveau ? AutofillHints.newPassword : AutofillHints.password
      ],
      decoration: InputDecoration(
        labelText: widget.libelle,
        helperText: widget.nouveau
            ? '8 caractères, avec majuscule, minuscule et chiffre'
            : null,
        suffixIcon: IconButton(
          tooltip: _visible ? 'Masquer' : 'Afficher',
          icon: Icon(_visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator:
          widget.validator ?? (v) => (v ?? '').isEmpty ? 'Obligatoire' : null,
    );
  }
}
