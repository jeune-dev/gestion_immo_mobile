import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/option_ref.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/account/domain/usecases/modifier_profil.dart';

/// Modification du profil (`PATCH /compte`) ; le mot de passe est exigé pour changer d'e-mail.
Future<void> modifierProfil(BuildContext context) async {
  final auth = context.read<AuthBloc>();
  final u = auth.state.compte?.utilisateur;
  if (u == null) return;
  await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Mon profil',
      initial: {
        'first_name': u.prenom,
        'last_name': u.nom,
        'email': u.email,
        'language': u.langue
      },
      champs: const [
        Champ('first_name', 'Prénom', obligatoire: true, maxLongueur: 80),
        Champ('last_name', 'Nom', obligatoire: true, maxLongueur: 80),
        Champ('email', 'E-mail', type: TypeChamp.email),
        Champ('language', 'Langue',
            type: TypeChamp.selection,
            options: [OptionRef('fr', 'Français'), OptionRef('en', 'Anglais')]),
        Champ('current_password', 'Mot de passe actuel',
            type: TypeChamp.motDePasse,
            indice: "Uniquement pour changer d'e-mail"),
      ],
      messageSucces: 'Profil mis à jour',
      envoyer: (c) async {
        if (c['email'] == u.email) c.remove('email');
        if (c['current_password'] == null) c.remove('current_password');
        (await sl<ModifierProfil>()(c)).ouLeve();
        auth.add(CompteRechargeDemande());
        return true;
      },
    ),
  );
}
