import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';

/// Erreur de la dernière demande d'authentification, en tête de formulaire.
class ErreurAuth extends StatelessWidget {
  const ErreurAuth({super.key});

  @override
  Widget build(BuildContext context) {
    final failure = context.select((AuthBloc b) => b.state.failure);
    if (failure == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
      child: Encadre(failure.messageComplet, ton: TonStatut.danger),
    );
  }
}

/// Bouton d'envoi désactivé pendant une demande en cours.
class BoutonAuth extends StatelessWidget {
  final String libelle;
  final VoidCallback onPressed;
  const BoutonAuth({super.key, required this.libelle, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enCours = context.select((AuthBloc b) => b.state.enCours);
    return FilledButton(
      onPressed: enCours ? null : onPressed,
      child: enCours
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(libelle),
    );
  }
}

/// Efface l'erreur laissée par un autre écran d'authentification.
void effacerErreurAuth(BuildContext context) {
  final bloc = context.read<AuthBloc>();
  if (bloc.state.failure != null || bloc.state.succes != null) {
    bloc.add(AuthErreurEffacee());
  }
}
