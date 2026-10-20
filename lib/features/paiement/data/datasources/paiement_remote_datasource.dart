import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/features/quittance/data/models/quittance_model.dart';
import '../models/paiement_model.dart';

abstract class PaiementRemoteDataSource {
  /// Idempotency-Key OBLIGATOIRE : un double envoi n'encaisse jamais deux fois. Renvoie le nombre de quittances produites.
  Future<int> encaisser(Map<String, dynamic> corps, {required String cle});
  Future<PageResultat<PaiementModel>> getPaiements(
      {required int page, String? moyen});
  Future<PaiementModel> getPaiement(String id);
  Future<List<QuittanceModel>> quittances(String id);
  Future<void> rembourser(String id, Map<String, dynamic> corps,
      {required String cle});

  Future<PageResultat<TransactionPaiementModel>> transactions(
      {required int page, String? statut, bool preuvesSeulement = false});
  Future<TransactionPaiementModel> transaction(String id);
  Future<void> validerTransaction(String id);
  Future<void> rejeterTransaction(String id, String motif);

  Future<PageResultat<RapprochementModel>> rapprochements(
      {required int page, String? statut});
  Future<void> resoudreRapprochement(String id, Map<String, dynamic> corps,
      {required String cle});
  Future<void> rejeterRapprochement(String id, Map<String, dynamic> corps);

  Future<List<MoyenPaiementModel>> moyens();
  Future<void> configurerMoyen(Map<String, dynamic> corps);
}

class PaiementRemoteDataSourceImpl implements PaiementRemoteDataSource {
  final ApiClient api;
  PaiementRemoteDataSourceImpl({required this.api});

  @override
  Future<int> encaisser(Map<String, dynamic> corps,
      {required String cle}) async {
    final r = await api.post<Map<String, dynamic>>(
        ApiEndpoints.paiementsEspeces,
        body: corps,
        idempotence: cle);
    return ((r['receipts'] as List?) ?? const []).length;
  }

  @override
  Future<PageResultat<PaiementModel>> getPaiements(
          {required int page, String? moyen}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.paiements,
            query: {'page': page, 'method': moyen, 'tri': '-paid_on'}),
        PaiementModel.fromJson,
      );

  @override
  Future<PaiementModel> getPaiement(String id) async =>
      PaiementModel.fromJson(Map<String, dynamic>.from((await api
              .get<Map<String, dynamic>>(ApiEndpoints.paiement(id)))['payment']
          as Map));

  @override
  Future<List<QuittanceModel>> quittances(String id) async {
    final r = await api
        .get<Map<String, dynamic>>(ApiEndpoints.paiementQuittances(id));
    return ((r['receipts'] as List?) ?? const [])
        .map(
            (q) => QuittanceModel.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  @override
  Future<void> rembourser(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.paiementRembourser(id),
          body: corps, idempotence: cle);

  @override
  Future<PageResultat<TransactionPaiementModel>> transactions(
          {required int page,
          String? statut,
          bool preuvesSeulement = false}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(
          ApiEndpoints.transactions,
          query: {
            'page': page,
            'status': statut,
            if (preuvesSeulement) 'mode': 'preuve',
            'tri': '-created_at'
          },
        ),
        TransactionPaiementModel.fromJson,
      );

  @override
  Future<TransactionPaiementModel> transaction(String id) async =>
      TransactionPaiementModel.fromJson(
        Map<String, dynamic>.from((await api.get<Map<String, dynamic>>(
            ApiEndpoints.transaction(id)))['transaction'] as Map),
      );

  @override
  Future<void> validerTransaction(String id) =>
      api.post<dynamic>(ApiEndpoints.transactionValider(id),
          idempotence: nouvelleCle());

  @override
  Future<void> rejeterTransaction(String id, String motif) =>
      api.post<dynamic>(ApiEndpoints.transactionRejeter(id),
          body: {'reason': motif});

  @override
  Future<PageResultat<RapprochementModel>> rapprochements(
          {required int page, String? statut}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.rapprochements,
            query: {'page': page, 'status': statut}),
        RapprochementModel.fromJson,
      );

  @override
  Future<void> resoudreRapprochement(String id, Map<String, dynamic> corps,
          {required String cle}) =>
      api.post<dynamic>(ApiEndpoints.rapprochementResoudre(id),
          body: corps, idempotence: cle);

  @override
  Future<void> rejeterRapprochement(String id, Map<String, dynamic> corps) =>
      api.post<dynamic>(ApiEndpoints.rapprochementRejeter(id), body: corps);

  @override
  Future<List<MoyenPaiementModel>> moyens() async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.moyensPaiement,
        cache: false);
    return ((r['providers'] as List?) ?? const [])
        .map((m) =>
            MoyenPaiementModel.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  @override
  Future<void> configurerMoyen(Map<String, dynamic> corps) =>
      api.put<dynamic>(ApiEndpoints.moyensPaiement, body: corps);
}
