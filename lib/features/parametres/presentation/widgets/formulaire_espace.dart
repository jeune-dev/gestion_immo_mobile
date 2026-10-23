import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/parametres/domain/usecases/get_parametres.dart';
import 'package:gestion_immo_mobile/features/parametres/domain/usecases/modifier_espace_bailleur.dart';

/// « Mon espace propriétaire » : nom affiché et coordonnées reprises sur les quittances.
Future<void> modifierEspaceBailleur(BuildContext context) async {
  final auth = context.read<AuthBloc>();
  final p = await executer(context, () => sl<GetParametres>()());
  if (p == null || !context.mounted) return;
  final e = p.espace;
  await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Mon espace propriétaire',
      initial: {
        'display_name': e.nomAffiche,
        'company_name': e.societe,
        'phone': e.telephone,
        'email': e.email,
        'address': e.adresse,
        'city': e.ville,
      },
      champs: const [
        Champ('display_name', 'Nom affiché',
            obligatoire: true, minLongueur: 2, maxLongueur: 150),
        Champ('company_name', 'Société', maxLongueur: 150),
        Champ('phone', 'Téléphone', type: TypeChamp.telephone),
        Champ('email', 'E-mail', type: TypeChamp.email),
        Champ('address', 'Adresse', maxLongueur: 255),
        Champ('city', 'Ville', maxLongueur: 100),
      ],
      messageSucces: 'Espace mis à jour',
      envoyer: (c) async {
        (await sl<ModifierEspaceBailleur>()(c)).ouLeve();
        auth.add(CompteRechargeDemande());
        return true;
      },
    ),
  );
}
