import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/option_ref.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/avatar_utilisateur.dart';
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
        'language': u.langue,
      },
      intro: const EditeurPhotoProfil(),
      champs: [
        const Champ(
          'first_name',
          'Prénom',
          type: TypeChamp.nom,
          obligatoire: true,
          maxLongueur: 80,
          groupe: 'Mes informations',
          moitie: true,
        ),
        const Champ(
          'last_name',
          'Nom',
          type: TypeChamp.nom,
          obligatoire: true,
          maxLongueur: 80,
          moitie: true,
        ),
        const Champ(
          'email',
          'E-mail',
          type: TypeChamp.email,
          icone: Icons.mail_outline,
        ),
        const Champ(
          'language',
          'Langue',
          type: TypeChamp.selection,
          options: [OptionRef('fr', 'Français'), OptionRef('en', 'Anglais')],
          icone: Icons.language,
        ),
        // Le mot de passe n'est demandé que si l'e-mail change.
        Champ(
          'current_password',
          'Mot de passe actuel',
          type: TypeChamp.motDePasse,
          obligatoire: true,
          indice: "Requis pour changer d'e-mail",
          groupe: 'Sécurité',
          icone: Icons.lock_outline,
          visible: (v) => '${v['email'] ?? ''}'.trim() != (u.email ?? ''),
        ),
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
