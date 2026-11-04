import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Demande confirmation, en annonçant ce que deviennent les opérations hors ligne.
Future<void> confirmerDeconnexion(BuildContext context) async {
  final n = GetIt.instance<FileAttenteService>().operations.length;
  final ok = await confirmer(
    context,
    titre: 'Se déconnecter',
    message: n == 0
        ? 'Les données enregistrées sur ce téléphone seront effacées.'
        : '$n opération(s) créée(s) hors ligne ne sont pas encore envoyées. '
              'Si le réseau manque, elles restent sur ce téléphone et partiront '
              'à votre prochaine connexion avec ce compte.',
    action: 'Se déconnecter',
  );
  if (ok != null && context.mounted) {
    context.read<AuthBloc>().add(DeconnexionDemandee());
  }
}
