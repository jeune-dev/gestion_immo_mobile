import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/widgets/actions.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Demande confirmation avant de fermer la session.
Future<void> confirmerDeconnexion(BuildContext context) async {
  final ok = await confirmer(
    context,
    titre: 'Se déconnecter',
    message: 'Vous devrez saisir à nouveau vos identifiants pour revenir.',
    action: 'Se déconnecter',
  );
  if (ok != null && context.mounted) {
    context.read<AuthBloc>().add(DeconnexionDemandee());
  }
}
