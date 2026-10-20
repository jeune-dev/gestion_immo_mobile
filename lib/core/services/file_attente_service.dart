import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';

/// Opération créée hors ligne, en attente d'envoi (cahier des charges § 34–35).
class OperationEnAttente {
  /// Sert aussi d'`Idempotency-Key` : un renvoi après coupure rejoue la réponse
  /// d'origine au lieu de créer un doublon.
  final String id;
  final String libelle;
  final String chemin;
  final Map<String, dynamic> corps;
  final DateTime creeLe;
  String? erreur;

  OperationEnAttente(
      {required this.id,
      required this.libelle,
      required this.chemin,
      required this.corps,
      required this.creeLe,
      this.erreur});

  Map<String, dynamic> toJson() => {
        'id': id,
        'libelle': libelle,
        'chemin': chemin,
        'corps': corps,
        'cree_le': creeLe.toIso8601String(),
        'erreur': erreur,
      };

  factory OperationEnAttente.fromJson(Map<String, dynamic> j) =>
      OperationEnAttente(
        id: j['id'] as String,
        libelle: j['libelle'] as String,
        chemin: j['chemin'] as String,
        corps: Map<String, dynamic>.from(j['corps'] as Map),
        creeLe: DateTime.parse(j['cree_le'] as String),
        erreur: j['erreur'] as String?,
      );
}

/// File des créations différées (dépenses, incidents) :
/// Application → API → Backend ; au retour du réseau : synchronisation → succès
/// → mise à jour locale ; échec : « Synchronisation impossible [Réessayer]
/// [Voir les opérations] ». Un paiement n'y passe JAMAIS (confirmation serveur obligatoire).
class FileAttenteService extends ChangeNotifier {
  static const _cle = 'gi.file_attente';
  final ApiClient _api;

  final List<OperationEnAttente> operations = [];
  bool synchronisation = false;
  bool echec = false;

  FileAttenteService(this._api);

  Future<void> charger() async {
    final p = await SharedPreferences.getInstance();
    final brut = p.getString(_cle);
    operations
      ..clear()
      ..addAll(brut == null
          ? const []
          : (jsonDecode(brut) as List).map((j) => OperationEnAttente.fromJson(
              Map<String, dynamic>.from(j as Map))));
    notifyListeners();
  }

  Future<void> _sauver() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _cle, jsonEncode(operations.map((o) => o.toJson()).toList()));
    notifyListeners();
  }

  /// Envoie tout de suite ; sans réseau, met l'opération en file et renvoie `null`.
  Future<T?> envoyerOuDifferer<T>(
      {required String libelle,
      required String chemin,
      required Map<String, dynamic> corps}) async {
    final id = nouvelleCle();
    try {
      return await _api.post<T>(chemin, body: corps, idempotence: id);
    } on ApiException catch (e) {
      if (!e.estReseau) rethrow;
      operations.add(OperationEnAttente(
          id: id,
          libelle: libelle,
          chemin: chemin,
          corps: corps,
          creeLe: DateTime.now()));
      await _sauver();
      return null;
    }
  }

  /// Rejoue les opérations en attente, dans l'ordre. Une erreur métier (4xx) est
  /// conservée sur l'opération pour que l'utilisateur la voie et la retire.
  Future<void> synchroniser() async {
    if (synchronisation || operations.isEmpty) return;
    synchronisation = true;
    echec = false;
    notifyListeners();
    for (final op in List.of(operations)) {
      try {
        await _api.post<dynamic>(op.chemin, body: op.corps, idempotence: op.id);
        operations.remove(op);
      } on ApiException catch (e) {
        if (e.estReseau) {
          echec = true;
          break;
        }
        op.erreur = e.messageComplet;
        echec = true;
      }
    }
    synchronisation = false;
    await _sauver();
  }

  Future<void> retirer(OperationEnAttente op) async {
    operations.remove(op);
    await _sauver();
  }

  Future<void> vider() async {
    operations.clear();
    await _sauver();
  }
}
