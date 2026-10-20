import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/option_ref.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/appartement/presentation/widgets/sources_appartement.dart';
import 'package:gestion_immo_mobile/features/artisan/presentation/widgets/sources_artisan.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/sources_immeuble.dart';
import 'package:gestion_immo_mobile/features/depense/domain/entities/depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/creer_depense.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/creer_depense_travaux.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/get_categories_depenses.dart';
import 'package:gestion_immo_mobile/features/depense/domain/usecases/modifier_depense.dart';

/// Catégories de dépenses actives (catalogue + catégories propres au propriétaire).
Future<List<OptionRef>?> _categories(BuildContext context) async {
  final r = await sl<GetCategoriesDepenses>()();
  return r.fold((f) {
    if (context.mounted) afficherErreurApi(context, f);
    return null;
  }, (cats) => [for (final c in cats) OptionRef(c.id, c.nom)]);
}

/// Saisie d'une dépense (§ 20). Hors ligne, elle est mise en file et
/// synchronisée au retour du réseau (§ 34) grâce à `client_reference`.
/// Avec [travauxId], la dépense est rattachée au chantier (§ 23 étape 7).
Future<bool> nouvelleDepense(BuildContext context,
    {String? travauxId, String? travauxTitre}) async {
  final categories = await _categories(context);
  if (categories == null || !context.mounted) return false;
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: travauxId == null ? 'Nouvelle dépense' : 'Dépense du chantier',
      initial: {'spent_on': aujourdhui(), 'method': 'especes'},
      intro: travauxId == null
          ? const Text(
              'Une dépense en espèces est aussi enregistrée dans la caisse.')
          : Text(travauxTitre ?? ''),
      champs: [
        if (travauxId == null)
          Champ('building_id', 'Immeuble',
              type: TypeChamp.entite,
              obligatoire: true,
              entite: sourceImmeubles()),
        Champ('category_id', 'Catégorie',
            type: TypeChamp.selection,
            options: categories,
            obligatoire: travauxId == null),
        const Champ('amount', 'Montant',
            type: TypeChamp.montant, obligatoire: true, min: 1),
        const Champ('method', 'Moyen de paiement',
            type: TypeChamp.selection,
            referentiel: 'mode_paiement',
            obligatoire: true),
        const Champ('spent_on', 'Date',
            type: TypeChamp.date, obligatoire: true),
        const Champ('description', 'Description',
            type: TypeChamp.multiligne, maxLongueur: 500),
        Champ('contractor_id', 'Artisan (facultatif)',
            type: TypeChamp.entite, entite: sourceArtisans()),
      ],
      libelleEnvoi: 'Enregistrer',
      envoyer: (corps) async {
        if (travauxId != null) {
          (await sl<CreerDepenseTravaux>()(travauxId, corps)).ouLeve();
          return true;
        }
        return (await sl<CreerDepense>()(corps)).ouLeve() ?? 'differee';
      },
    ),
  );
  if (r == null || !context.mounted) return false;
  afficherSucces(
      context,
      r == 'differee'
          ? 'Hors ligne : la dépense sera envoyée au retour du réseau.'
          : 'Dépense enregistrée');
  return true;
}

/// Correction d'une dépense (`PATCH /depenses/:id`) : classification, appartement,
/// artisan et description. Le montant, le moyen et la date ne se modifient pas :
/// une erreur se corrige en annulant la dépense puis en la ressaisissant.
Future<bool> modifierDepense(BuildContext context, Depense d) async {
  var categories = await _categories(context);
  if (categories == null || !context.mounted) return false;
  // Catégorie désactivée depuis : elle reste proposée pour ne pas forcer un changement
  if (d.categorieId != null &&
      !categories.any((o) => o.code == d.categorieId)) {
    categories = [
      OptionRef(d.categorieId!,
          '${d.categorieNom ?? 'Catégorie actuelle'} (désactivée)'),
      ...categories
    ];
  }
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Modifier la dépense',
      intro: const Text(
          'Le montant, le moyen et la date ne se modifient pas : annulez la dépense et ressaisissez-la si besoin.'),
      initial: {
        'category_id': d.categorieId,
        'description': d.description,
        'apartment_id': d.appartementId,
        if (d.appartementNumero != null)
          'apartment_id__libelle': 'Appartement ${d.appartementNumero}',
        'contractor_id': d.artisanId,
        if (d.artisanNom != null) 'contractor_id__libelle': d.artisanNom,
      },
      champs: [
        Champ('category_id', 'Catégorie',
            type: TypeChamp.selection, options: categories, obligatoire: true),
        Champ(
          'apartment_id',
          'Appartement (facultatif)',
          type: TypeChamp.entite,
          nullable: true,
          entite: sourceAppartements(immeuble: d.immeubleId),
        ),
        Champ('contractor_id', 'Artisan (facultatif)',
            type: TypeChamp.entite, nullable: true, entite: sourceArtisans()),
        const Champ('description', 'Description',
            type: TypeChamp.multiligne, maxLongueur: 500),
      ],
      messageSucces: 'Dépense modifiée',
      envoyer: (corps) async =>
          (await sl<ModifierDepense>()(d.id, corps)).ouLeve(),
    ),
  );
  return r != null;
}
