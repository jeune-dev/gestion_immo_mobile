import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/depense/domain/entities/depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/creer_categorie_depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/modifier_categorie_depense.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/bloc/categories_bloc.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/bloc/categories_event.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/bloc/categories_state.dart';

/// Catégories de dépenses : catalogue commun + catégories propres au propriétaire.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _formulaire(BuildContext context, VoidCallback recharger,
      {CategorieDepense? existant}) async {
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre:
            existant == null ? 'Nouvelle catégorie' : 'Modifier la catégorie',
        initial: existant == null
            ? const {}
            : {'name': existant.nom, 'cash_group': existant.groupeCaisse},
        champs: const [
          Champ('name', 'Nom', obligatoire: true, maxLongueur: 100),
          Champ('cash_group', 'Groupe de caisse',
              type: TypeChamp.selection,
              referentiel: 'groupe_caisse_sortie',
              obligatoire: true),
        ],
        messageSucces: 'Catégorie enregistrée',
        envoyer: (c) async {
          (existant == null
                  ? await di.sl<CreerCategorieDepense>()(c)
                  : await di.sl<ModifierCategorieDepense>()(existant.id, c))
              .ouLeve();
          return true;
        },
      ),
    );
    if (r != null) recharger();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CategoriesBloc>()..add(LoadCategories()),
      child: BlocConsumer<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategoriesSuccess) {
            afficherSucces(context, state.message);
          } else if (state is CategoriesActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is CategoriesInitial ||
            state is CategoriesLoading ||
            state is CategoriesLoaded ||
            state is CategoriesError,
        builder: (context, state) {
          if (state is CategoriesLoaded) {
            return _buildFiche(context, state.categories);
          }
          return VueChargement(
            titre: 'Catégories de dépenses',
            failure: state is CategoriesError ? state.failure : null,
            onReessayer: () =>
                context.read<CategoriesBloc>().add(LoadCategories()),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, List<CategorieDepense> cats) {
    final bloc = context.read<CategoriesBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories de dépenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _formulaire(context, () => bloc.add(RafraichirCategories())),
        icon: const Icon(Icons.add),
        label: const Text('Catégorie'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          for (final c in cats)
            ListTile(
              title: Text(c.nom),
              subtitle: Text(
                  '${refs.libelle('groupe_caisse_sortie', c.groupeCaisse)}${c.catalogue ? ' · catalogue' : ''}'),
              trailing: c.active
                  ? (c.catalogue
                      ? null
                      : IconButton(
                          tooltip: 'Désactiver',
                          icon: const Icon(Icons.visibility_off_outlined),
                          onPressed: () =>
                              bloc.add(DesactiverCategorieEvent(c.id)),
                        ))
                  : const Pastille('Inactive'),
              onTap: c.catalogue
                  ? null
                  : () => _formulaire(
                      context, () => bloc.add(RafraichirCategories()),
                      existant: c),
            ),
        ],
      ),
    );
  }
}
