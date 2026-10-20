import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:gestion_immo_mobile/core/config/env.dart';
import 'package:gestion_immo_mobile/core/constants/api_endpoints.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';

/// Clé d'idempotence : un UUID neuf par action utilisateur (contrat § 0).
String nouvelleCle() => const Uuid().v4();

/// Client de l'API (contrat § 0) :
/// - enveloppe `{ success, message, data }` : renvoie `data` ;
/// - 401 → UN renouvellement de session (une seule requête en vol) puis rejeu ;
/// - erreurs normalisées en [ApiException] (`error.code`) ;
/// - lectures mises en cache pour la consultation hors ligne (cahier des charges § 34).
class ApiClient {
  final TokenService session;
  final Dio _dio;

  /// Appelé quand la session ne peut plus être renouvelée (retour à la connexion).
  VoidCallback? onSessionExpiree;

  /// Vrai quand la dernière lecture vient du cache local (pas de réseau).
  final ValueNotifier<bool> horsLigne = ValueNotifier(false);

  String get baseUrl => _dio.options.baseUrl;

  Completer<bool>? _renouvellement;

  ApiClient({required this.session, String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? Env.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {'Accept': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = session.accessToken;
          if (token != null && options.extra['sansJeton'] != true) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // ── Session ────────────────────────────────────────────────────────────────

  /// Renouvelle la session avec le refresh token du coffre. Une seule requête
  /// en vol : réutiliser un ancien refresh token révoquerait toute la session.
  Future<bool> renouveler() {
    final enCours = _renouvellement;
    if (enCours != null) return enCours.future;
    final c = _renouvellement = Completer<bool>();
    () async {
      try {
        final refresh = await session.lireRefresh();
        if (refresh == null) return c.complete(false);
        final r = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.refresh,
          data: {'refresh_token': refresh},
          options: Options(extra: {'sansJeton': true}),
        );
        final data = r.data!['data'] as Map<String, dynamic>;
        await session.enregistrer(
            access: data['access_token'] as String,
            refresh: data['refresh_token'] as String?);
        c.complete(true);
      } on DioException catch (e) {
        // Refus explicite (401) : session terminée. Erreur réseau : on garde le jeton pour plus tard.
        if (e.response?.statusCode == 401) await session.effacer();
        c.complete(false);
      } catch (_) {
        c.complete(false);
      } finally {
        _renouvellement = null;
      }
    }();
    return c.future;
  }

  // ── Requêtes ───────────────────────────────────────────────────────────────

  Future<T> _executer<T>(Future<Response<dynamic>> Function() appel,
      {bool rejouable = true}) async {
    try {
      final r = await appel();
      return _deballer<T>(r.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          rejouable &&
          session.accessToken != null) {
        if (await renouveler()) return _executer<T>(appel, rejouable: false);
        onSessionExpiree?.call();
      }
      throw await _normaliser(e);
    }
  }

  T _deballer<T>(dynamic corps) {
    if (corps is Map<String, dynamic> && corps.containsKey('success')) {
      return corps['data'] as T;
    }
    return corps as T;
  }

  Future<ApiException> _normaliser(DioException e) async {
    final r = e.response;
    if (r == null) {
      // En développement, l'adresse visée aide à diagnostiquer (mauvaise IP, réseau local refusé…)
      final detail = kDebugMode ? '\n(${_dio.options.baseUrl})' : '';
      return ApiException(
          "Impossible de joindre le serveur. Vérifiez votre connexion.$detail",
          code: 'RESEAU');
    }
    dynamic corps = r.data;
    if (corps is List<int>) {
      try {
        corps = jsonDecode(utf8.decode(corps));
      } catch (_) {
        corps = null;
      }
    }
    final erreur = corps is Map ? corps['error'] as Map? : null;
    var message = (corps is Map ? corps['message'] as String? : null) ??
        erreur?['message'] as String? ??
        'Erreur inattendue';
    final status = r.statusCode;
    if (status == 429) {
      message =
          'Trop de requêtes : patientez quelques instants avant de réessayer.';
    }
    final retry = int.tryParse(r.headers.value('retry-after') ?? '');
    return ApiException(
      message,
      status: status,
      code: erreur?['code'] as String?,
      details:
          ((erreur?['details'] as List?) ?? const []).map((d) => '$d').toList(),
      requestId: (corps is Map ? corps['requestId'] as String? : null) ??
          r.headers.value('x-request-id'),
      retryAfter: retry,
    );
  }

  Map<String, dynamic>? _nettoyer(Map<String, dynamic>? q) {
    if (q == null) return null;
    final r = <String, dynamic>{};
    q.forEach((k, v) {
      if (v == null || (v is String && v.isEmpty)) return;
      r[k] = v;
    });
    return r;
  }

  Options _options(String? idempotence) => Options(
      headers: idempotence != null ? {'Idempotency-Key': idempotence} : null);

  /// Lecture. Hors ligne, renvoie la dernière réponse connue (si [cache]).
  Future<T> get<T>(String chemin,
      {Map<String, dynamic>? query, bool cache = true}) async {
    final q = _nettoyer(query);
    final cle =
        'cache:$chemin?${q == null ? '' : Uri(queryParameters: q.map((k, v) => MapEntry(k, '$v'))).query}';
    try {
      final data = await _executer<dynamic>(
          () => _dio.get<dynamic>(chemin, queryParameters: q));
      horsLigne.value = false;
      if (cache) unawaited(_memoriser(cle, data));
      return data as T;
    } on ApiException catch (e) {
      if (e.estReseau && cache) {
        final p = await SharedPreferences.getInstance();
        final brut = p.getString(cle);
        if (brut != null) {
          horsLigne.value = true;
          return jsonDecode(brut) as T;
        }
      }
      rethrow;
    }
  }

  Future<void> _memoriser(String cle, dynamic data) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(cle, jsonEncode(data));
    } catch (_) {
      // Le cache est une commodité : son échec ne bloque rien
    }
  }

  /// Vide le cache de lecture (déconnexion : aucune donnée ne doit rester sur l'appareil).
  static Future<void> viderCache() async {
    final p = await SharedPreferences.getInstance();
    for (final k in p.getKeys().where((k) => k.startsWith('cache:')).toList()) {
      await p.remove(k);
    }
  }

  Future<T> post<T>(String chemin,
          {Object? body, String? idempotence, bool sansJeton = false}) =>
      _executer<T>(
        () => _dio.post<dynamic>(
          chemin,
          data: body ?? const <String, dynamic>{},
          options:
              _options(idempotence).copyWith(extra: {'sansJeton': sansJeton}),
        ),
        rejouable: !sansJeton,
      );

  Future<T> patch<T>(String chemin, {Object? body}) => _executer<T>(() =>
      _dio.patch<dynamic>(chemin, data: body ?? const <String, dynamic>{}));

  Future<T> put<T>(String chemin, {Object? body}) => _executer<T>(
      () => _dio.put<dynamic>(chemin, data: body ?? const <String, dynamic>{}));

  Future<T> delete<T>(String chemin, {Object? body}) =>
      _executer<T>(() => _dio.delete<dynamic>(chemin, data: body));

  /// Envoi multipart : fichier dans le champ `fichier` (contrat § 0 « Envoi de fichiers »).
  Future<T> upload<T>(
    String chemin, {
    String? cheminFichier,
    Map<String, dynamic> champs = const {},
    String? idempotence,
    String champFichier = 'fichier',
  }) {
    return _executer<T>(() async {
      final form = FormData.fromMap({
        for (final e in champs.entries)
          if (e.value != null)
            e.key: e.value is String ? e.value : '${e.value}',
        if (cheminFichier != null)
          champFichier: await MultipartFile.fromFile(cheminFichier),
      });
      return _dio.post<dynamic>(chemin,
          data: form, options: _options(idempotence));
    });
  }

  /// Fichier binaire (PDF de quittance, état des lieux, contrat, export CSV).
  /// 503 `QUITTANCE_EN_PREPARATION` : nouvelle tentative après le délai indiqué.
  Future<Uint8List> telecharger(String chemin,
      {Map<String, dynamic>? query, int tentatives = 3}) async {
    for (var i = 0;; i++) {
      try {
        final octets = await _executer<List<int>>(
          () => _dio.get<List<int>>(
            chemin,
            queryParameters: _nettoyer(query),
            options: Options(responseType: ResponseType.bytes),
          ),
        );
        return Uint8List.fromList(octets);
      } on ApiException catch (e) {
        if (e.status == 503 && i < tentatives - 1) {
          await Future<void>.delayed(Duration(seconds: e.retryAfter ?? 5));
          continue;
        }
        rethrow;
      }
    }
  }
}
