import 'dart:typed_data';

import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/file_attente_service.dart';
import 'package:gestion_immo_mobile/features/caution/data/models/caution_model.dart';
import 'package:gestion_immo_mobile/features/echeance/data/models/echeance_model.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/data/models/etat_des_lieux_model.dart';
import 'package:gestion_immo_mobile/features/facture_commune/data/models/facture_commune_model.dart';
import 'package:gestion_immo_mobile/features/incident/data/models/incident_model.dart';
import 'package:gestion_immo_mobile/features/paiement/data/models/paiement_model.dart';
import '../../domain/entities/espace_locataire.dart';
import '../models/espace_locataire_model.dart';

/// Espace locataire (§ 28) : le locataire ne voit jamais les autres locataires.
abstract class EspaceLocataireRemoteDataSource {
  Future<List<LogementLocataire>> accueil();
  Future<List<LogementLocataire>> logements();
  Future<PageResultat<EcheanceModel>> echeances(
      {required int page, required bool aPayer});
  Future<PageResultat<PaiementModel>> paiements({required int page});
  Future<PageResultat<TransactionPaiementModel>> transactions(
      {required int page});
  Future<TransactionPaiementModel> transaction(String id);
  Future<MoyensPaiementLocataire> moyensPaiement(String bailId);

  /// Paiement intégré (PayDunya) d'une échéance ou d'une charge.
  Future<DemandePaiement> payer(
      {String? echeanceId,
      String? chargeId,
      required String portefeuille,
      int? montant});

  /// Paiement direct déclaré avec sa preuve (capture facultative).
  Future<void> declarerPreuve(Map<String, dynamic> champs, {String? capture});
  Future<List<CautionModel>> cautions();
  Future<void> contesterRetenue(String mouvementId, String message);
  Future<PageResultat<ChargeRefactureeModel>> charges({required int page});
  Future<void> consentementWhatsapp({required bool accorde});
  Future<PageResultat<IncidentModel>> incidents({required int page});
  Future<IncidentModel> incident(String id);

  /// Sans réseau, le signalement est mis en file (§ 34) et `null` est renvoyé.
  Future<IncidentModel?> signalerOuDifferer(Map<String, dynamic> corps);
  Future<void> ajouterPieceIncident(String id, String chemin);
  Future<PageResultat<EtatDesLieuxModel>> etatsDesLieux({required int page});
  Future<EtatDesLieuxModel> etatDesLieux(String id);
  Future<Uint8List> pdfEtatDesLieux(String id);
  Future<void> accepterEtatDesLieux(String id);
  Future<void> contesterEtatDesLieux(String id, String commentaire);
}

class EspaceLocataireRemoteDataSourceImpl
    implements EspaceLocataireRemoteDataSource {
  final ApiClient api;
  final FileAttenteService fileAttente;
  EspaceLocataireRemoteDataSourceImpl(
      {required this.api, required this.fileAttente});

  @override
  Future<List<LogementLocataire>> accueil() async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.locAccueil);
    return ((r['homes'] as List?) ?? const []).map((h) {
      final accueil = Map<String, dynamic>.from(h as Map);
      return EspaceLocataireModel.logement(
          Map<String, dynamic>.from(accueil['lease'] as Map),
          accueil: accueil);
    }).toList();
  }

  @override
  Future<List<LogementLocataire>> logements() async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.locLogement);
    return ((r['leases'] as List?) ?? const [])
        .map((b) =>
            EspaceLocataireModel.logement(Map<String, dynamic>.from(b as Map)))
        .toList();
  }

  @override
  Future<PageResultat<EcheanceModel>> echeances(
          {required int page, required bool aPayer}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(
          ApiEndpoints.locEcheances,
          query: {
            'page': page,
            if (aPayer) 'a_payer': true,
            'ordre': aPayer ? 'asc' : 'desc'
          },
        ),
        EcheanceModel.fromJson,
      );

  @override
  Future<PageResultat<PaiementModel>> paiements({required int page}) async =>
      PageResultat.depuisJson(
          await api.get<Map<String, dynamic>>(ApiEndpoints.locPaiements,
              query: {'page': page}),
          PaiementModel.fromJson);

  @override
  Future<PageResultat<TransactionPaiementModel>> transactions(
          {required int page}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.locTransactions,
            query: {'page': page}),
        TransactionPaiementModel.fromJson,
      );

  @override
  Future<TransactionPaiementModel> transaction(String id) async =>
      TransactionPaiementModel.fromJson(
        Map<String, dynamic>.from((await api.get<Map<String, dynamic>>(
            ApiEndpoints.locTransaction(id),
            cache: false))['transaction'] as Map),
      );

  @override
  Future<MoyensPaiementLocataire> moyensPaiement(String bailId) async {
    final r = await api.get<Map<String, dynamic>>(
        ApiEndpoints.locPaiementsMoyens,
        query: {'lease_id': bailId},
        cache: false);
    return EspaceLocataireModel.moyens(
        Map<String, dynamic>.from(r['methods'] as Map));
  }

  /// Idempotency-Key OBLIGATOIRE : un double toucher ne crée qu'une demande.
  @override
  Future<DemandePaiement> payer(
      {String? echeanceId,
      String? chargeId,
      required String portefeuille,
      int? montant}) async {
    final r = await api.post<Map<String, dynamic>>(
      ApiEndpoints.locPaiements,
      body: {
        if (echeanceId != null) 'rent_schedule_id': echeanceId,
        if (chargeId != null) 'charge_id': chargeId,
        'wallet': portefeuille,
        if (montant != null) 'amount': montant
      },
      idempotence: nouvelleCle(),
    );
    return DemandePaiement(
        transactionId: '${(r['transaction'] as Map)['id']}',
        checkoutUrl: r['checkout_url'] as String?);
  }

  @override
  Future<void> declarerPreuve(Map<String, dynamic> champs, {String? capture}) =>
      api.upload<dynamic>(ApiEndpoints.locPreuves,
          cheminFichier: capture, champs: champs, idempotence: nouvelleCle());

  @override
  Future<List<CautionModel>> cautions() async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.locCaution,
        cache: false);
    return ((r['deposits'] as List?) ?? const [])
        .map((c) => CautionModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  @override
  Future<void> contesterRetenue(String mouvementId, String message) =>
      api.post<dynamic>(ApiEndpoints.locContesterRetenue(mouvementId),
          body: {'message': message});

  @override
  Future<PageResultat<ChargeRefactureeModel>> charges(
          {required int page}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.locCharges,
            query: {'page': page, 'tri': '-due_date'}),
        ChargeRefactureeModel.fromJson,
      );

  @override
  Future<void> consentementWhatsapp({required bool accorde}) => api
      .post<dynamic>(ApiEndpoints.locConsentement, body: {'accorde': accorde});

  @override
  Future<PageResultat<IncidentModel>> incidents({required int page}) async =>
      PageResultat.depuisJson(
          await api.get<Map<String, dynamic>>(ApiEndpoints.locIncidents,
              query: {'page': page}),
          IncidentModel.fromJson);

  @override
  Future<IncidentModel> incident(String id) async => IncidentModel.fromJson(
        Map<String, dynamic>.from((await api.get<Map<String, dynamic>>(
            ApiEndpoints.locIncident(id),
            cache: false))['incident'] as Map),
      );

  @override
  Future<IncidentModel?> signalerOuDifferer(Map<String, dynamic> corps) async {
    final r = await fileAttente.envoyerOuDifferer<Map<String, dynamic>>(
      libelle: 'Signalement : ${corps['title']}',
      chemin: ApiEndpoints.locIncidents,
      // `client_reference` : deux synchronisations du même signalement n'en créent qu'un
      corps: {...corps, 'client_reference': 'inc-${nouvelleCle()}'},
    );
    return r == null
        ? null
        : IncidentModel.fromJson(
            Map<String, dynamic>.from(r['incident'] as Map));
  }

  @override
  Future<void> ajouterPieceIncident(String id, String chemin) =>
      api.upload<dynamic>(ApiEndpoints.locIncidentPieces(id),
          cheminFichier: chemin, idempotence: nouvelleCle());

  @override
  Future<PageResultat<EtatDesLieuxModel>> etatsDesLieux(
          {required int page}) async =>
      PageResultat.depuisJson(
        await api.get<Map<String, dynamic>>(ApiEndpoints.locEtatsDesLieux,
            query: {'page': page, 'tri': '-created_at'}),
        EtatDesLieuxModel.fromJson,
      );

  @override
  Future<EtatDesLieuxModel> etatDesLieux(String id) async =>
      EtatDesLieuxModel.fromJson(
        Map<String, dynamic>.from((await api.get<Map<String, dynamic>>(
            ApiEndpoints.locEtatDesLieux(id),
            cache: false))['inspection'] as Map),
      );

  @override
  Future<Uint8List> pdfEtatDesLieux(String id) =>
      api.telecharger(ApiEndpoints.locEtatDesLieuxPdf(id));

  @override
  Future<void> accepterEtatDesLieux(String id) =>
      api.post<dynamic>(ApiEndpoints.locEtatDesLieuxAction(id, 'accepter'),
          idempotence: nouvelleCle());

  @override
  Future<void> contesterEtatDesLieux(String id, String commentaire) =>
      api.post<dynamic>(ApiEndpoints.locEtatDesLieuxAction(id, 'contester'),
          body: {'comment': commentaire}, idempotence: nouvelleCle());
}
