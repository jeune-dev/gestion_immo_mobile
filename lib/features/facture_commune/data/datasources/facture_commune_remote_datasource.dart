import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/facture_commune.dart';
import '../models/facture_commune_model.dart';

abstract class FactureCommuneRemoteDataSource {
  Future<PageResultat<FactureCommuneModel>> getFacturesCommunes(
      {required int page, String? statut});
  Future<FacturesARepartir> aRepartir();
  Future<FactureCommuneModel> getFactureCommune(String id);
  Future<FactureCommuneModel> creerFactureCommune(Map<String, dynamic> corps,
      {required String cle});
  Future<FactureCommuneModel> modifierFactureCommune(
      String id, Map<String, dynamic> corps);
  Future<void> joindreDocument(String id, String chemin);
  Future<ApercuRepartitionModel> apercu(String id, Map<String, dynamic> corps);
  Future<void> repartir(String id, Map<String, dynamic> corps);
  Future<void> annulerFactureCommune(String id, String motif);
  Future<PageResultat<ChargeRefactureeModel>> charges(
      {required int page, String? statut});
}

class FactureCommuneRemoteDataSourceImpl
    implements FactureCommuneRemoteDataSource {
  final ApiClient api;
  FactureCommuneRemoteDataSourceImpl({required this.api});

  FactureCommuneModel _facture(Map<String, dynamic> r) =>
      FactureCommuneModel.fromJson(
          Map<String, dynamic>.from(r['invoice'] as Map));

  @override
  Future<PageResultat<FactureCommuneModel>> getFacturesCommunes(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.facturesCommunes,
            query: {'page': page, 'status': statut, 'tri': '-period_start'}),
        FactureCommuneModel.fromJson,
      );

  @override
  Future<FacturesARepartir> aRepartir() async {
    final r =
        await api.get<Map<String, dynamic>>(ApiEndpoints.facturesARepartir);
    return FacturesARepartir(
        nombre: entier(r['count']), total: nombreOuNull(r['total_amount']));
  }

  @override
  Future<FactureCommuneModel> getFactureCommune(String id) async => _facture(
      await api.get<Map<String, dynamic>>(ApiEndpoints.factureCommune(id)));

  @override
  Future<FactureCommuneModel> creerFactureCommune(Map<String, dynamic> corps,
          {required String cle}) async =>
      _facture(await api.post<Map<String, dynamic>>(
          ApiEndpoints.facturesCommunes,
          body: corps,
          idempotence: cle));

  @override
  Future<FactureCommuneModel> modifierFactureCommune(
          String id, Map<String, dynamic> corps) async =>
      _facture(await api.patch<Map<String, dynamic>>(
          ApiEndpoints.factureCommune(id),
          body: corps));

  @override
  Future<void> joindreDocument(String id, String chemin) => api
      .upload<dynamic>(ApiEndpoints.factureDocument(id), cheminFichier: chemin);

  @override
  Future<ApercuRepartitionModel> apercu(
      String id, Map<String, dynamic> corps) async {
    final r = await api.post<Map<String, dynamic>>(
        ApiEndpoints.factureApercu(id),
        body: corps);
    return ApercuRepartitionModel.fromJson(
        Map<String, dynamic>.from(r['allocation'] as Map));
  }

  @override
  Future<void> repartir(String id, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.factureRepartir(id), body: corps);

  @override
  Future<void> annulerFactureCommune(String id, String motif) => api
      .post<dynamic>(ApiEndpoints.factureAnnuler(id), body: {'reason': motif});

  @override
  Future<PageResultat<ChargeRefactureeModel>> charges(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.charges,
            query: {'page': page, 'status': statut, 'tri': '-due_date'}),
        ChargeRefactureeModel.fromJson,
      );
}
