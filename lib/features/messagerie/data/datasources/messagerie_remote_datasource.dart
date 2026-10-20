import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import '../models/messagerie_model.dart';

/// Messagerie des deux espaces : propriétaire (`/messagerie`) et locataire (`/locataire/messagerie`).
abstract class MessagerieRemoteDataSource {
  Future<PageResultat<FilDiscussionModel>> fils(
      {required int page, required bool espaceLocataire, int? limite});

  /// Les 100 derniers messages, du plus ancien au plus récent.
  Future<List<MessageModel>> messages(String filId,
      {required bool espaceLocataire});
  Future<void> marquerLu(String filId, {required bool espaceLocataire});

  /// Le propriétaire écrit à un locataire (le fil est créé au premier message) ;
  /// le locataire répond dans un fil existant.
  Future<MessageModel> envoyerTexte(String texte,
      {String? filId, String? locataireId});
  Future<MessageModel> envoyerPhoto(String chemin,
      {String? filId, String? locataireId});
}

class MessagerieRemoteDataSourceImpl implements MessagerieRemoteDataSource {
  final ApiClient api;
  MessagerieRemoteDataSourceImpl({required this.api});

  MessageModel _message(Map<String, dynamic> r) =>
      MessageModel.fromJson(Map<String, dynamic>.from(r['message'] as Map));

  @override
  Future<PageResultat<FilDiscussionModel>> fils(
          {required int page,
          required bool espaceLocataire,
          int? limite}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(
          espaceLocataire
              ? ApiEndpoints.locFils
              : ApiEndpoints.filsProprietaire,
          query: {'page': page, 'limit': limite},
        ),
        FilDiscussionModel.fromJson,
      );

  @override
  Future<List<MessageModel>> messages(String filId,
      {required bool espaceLocataire}) async {
    final r = await api.get<Map<String, dynamic>>(
      espaceLocataire
          ? ApiEndpoints.locFilMessages(filId)
          : ApiEndpoints.filProprietaireMessages(filId),
      query: {'limit': 100},
    );
    return PageResultat.depuisJson(r, MessageModel.fromJson).items.toList()
      ..sort((a, b) => '${a.creeLe}'.compareTo('${b.creeLe}'));
  }

  @override
  Future<void> marquerLu(String filId, {required bool espaceLocataire}) =>
      api.post<dynamic>(espaceLocataire
          ? ApiEndpoints.locFilLu(filId)
          : ApiEndpoints.filProprietaireLu(filId));

  @override
  Future<MessageModel> envoyerTexte(String texte,
          {String? filId, String? locataireId}) async =>
      _message(
        await api.post<Map<String, dynamic>>(
          locataireId != null
              ? ApiEndpoints.messageAuLocataire(locataireId)
              : ApiEndpoints.locFilMessages(filId!),
          body: {'body': texte},
          idempotence: nouvelleCle(),
        ),
      );

  @override
  Future<MessageModel> envoyerPhoto(String chemin,
          {String? filId, String? locataireId}) async =>
      _message(
        await api.upload<Map<String, dynamic>>(
          locataireId != null
              ? ApiEndpoints.photoAuLocataire(locataireId)
              : ApiEndpoints.locFilPhotos(filId!),
          cheminFichier: chemin,
          idempotence: nouvelleCle(),
        ),
      );
}
