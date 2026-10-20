import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../models/depense_model.dart';

abstract class DepenseRemoteDataSource {
  Future<PageResultat<DepenseModel>> getDepenses(
      {required int page, String? statut});

  /// Sans réseau, la dépense est mise en file (§ 34) et `null` est renvoyé.
  Future<DepenseModel?> creerOuDifferer(Map<String, dynamic> corps);
  Future<void> creerPourTravaux(String travauxId, Map<String, dynamic> corps);
  Future<DepenseModel> modifierDepense(String id, Map<String, dynamic> corps);
  Future<void> annulerDepense(String id, String motif);
  Future<void> ajouterJustificatif(String id, String chemin);
  Future<List<CategorieDepenseModel>> categories(
      {bool inclureInactives = false});
  Future<void> creerCategorie(Map<String, dynamic> corps);
  Future<void> modifierCategorie(String id, Map<String, dynamic> corps);
  Future<void> desactiverCategorie(String id);
}

class DepenseRemoteDataSourceImpl implements DepenseRemoteDataSource {
  final ApiClient api;
  final FileAttenteService fileAttente;
  DepenseRemoteDataSourceImpl({required this.api, required this.fileAttente});

  @override
  Future<PageResultat<DepenseModel>> getDepenses(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.depenses,
            query: {'page': page, 'status': statut, 'tri': '-spent_on'}),
        DepenseModel.fromJson,
      );

  @override
  Future<DepenseModel?> creerOuDifferer(Map<String, dynamic> corps) async {
    // `client_reference` permet de synchroniser la dépense au retour du réseau sans doublon
    corps['client_reference'] = 'dep-${nouvelleCle()}';
    final r = await fileAttente.envoyerOuDifferer<Map<String, dynamic>>(
      libelle:
          'Dépense de ${montant(lireMontant('${corps['amount']}') ?? corps['amount'] as num?)}',
      chemin: ApiEndpoints.depenses,
      corps: corps,
    );
    return r == null
        ? null
        : DepenseModel.fromJson(Map<String, dynamic>.from(r['expense'] as Map));
  }

  @override
  Future<void> creerPourTravaux(String travauxId, Map<String, dynamic> corps) =>
      api.post<dynamic>(
        ApiEndpoints.travauxDepenses(travauxId),
        body: {...corps, 'client_reference': 'dep-${nouvelleCle()}'},
        idempotence: nouvelleCle(),
      );

  @override
  Future<DepenseModel> modifierDepense(
          String id, Map<String, dynamic> corps) async =>
      DepenseModel.fromJson(
        Map<String, dynamic>.from((await api.patch<Map<String, dynamic>>(
            ApiEndpoints.depense(id),
            body: corps))['expense'] as Map),
      );

  @override
  Future<void> annulerDepense(String id, String motif) => api
      .post<dynamic>(ApiEndpoints.depenseAnnuler(id), body: {'reason': motif});

  @override
  Future<void> ajouterJustificatif(String id, String chemin) =>
      api.upload<dynamic>(ApiEndpoints.depenseJustificatifs(id),
          cheminFichier: chemin);

  @override
  Future<List<CategorieDepenseModel>> categories(
      {bool inclureInactives = false}) async {
    final r = await api.get<Map<String, dynamic>>(
      ApiEndpoints.categoriesDepenses,
      query: {if (inclureInactives) 'inclure_inactives': true},
      cache: !inclureInactives,
    );
    return ((r['categories'] as List?) ?? const [])
        .map((c) =>
            CategorieDepenseModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  @override
  Future<void> creerCategorie(Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.categoriesDepenses, body: corps);

  @override
  Future<void> modifierCategorie(String id, Map<String, dynamic> corps) =>
      api.patch<dynamic>(ApiEndpoints.categorieDepense(id), body: corps);

  @override
  Future<void> desactiverCategorie(String id) =>
      api.post<dynamic>(ApiEndpoints.categorieDesactiver(id));
}
