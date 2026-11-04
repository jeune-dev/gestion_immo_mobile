import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/coffre_local.dart';

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

  OperationEnAttente({
    required this.id,
    required this.libelle,
    required this.chemin,
    required this.corps,
    required this.creeLe,
    this.erreur,
  });

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
  static const _cleAncienne = 'gi.file_attente';
  final ApiClient _api;

  final List<OperationEnAttente> operations = [];
  bool synchronisation = false;
  bool echec = false;

  final CoffreLocal _coffre;

  /// Chaque compte a sa file : une déconnexion la conserve, et un autre compte
  /// du même téléphone ne la voit ni ne l'envoie.
  String? _compteId;
  Future<void>? _envoiEnCours;

  FileAttenteService(this._api, [CoffreLocal? coffre])
    : _coffre = coffre ?? CoffreLocal();

  String get _cle => '$_cleAncienne.$_compteId';

  /// Charge la file du compte connecté et relance l'envoi de ce qui attendait.
  Future<void> ouvrirSession(String compteId) async {
    if (_compteId == compteId) return;
    await _envoiEnCours;
    _compteId = compteId;
    echec = false;
    final p = await SharedPreferences.getInstance();
    operations
      ..clear()
      ..addAll(await _lire(p.getString(_cle)));
    // Ancienne file, sans compte : elle appartient à la session restée ouverte.
    final ancienne = p.getString(_cleAncienne);
    if (ancienne != null) {
      operations.addAll(await _lire(ancienne));
      await _sauver();
      await p.remove(_cleAncienne);
    }
    notifyListeners();
    if (operations.isNotEmpty) unawaited(synchroniser());
  }

  /// Fin de session : la file reste sur le téléphone, chiffrée, pour ce compte.
  Future<void> fermerSession() async {
    await _envoiEnCours;
    _compteId = null;
    operations.clear();
    echec = false;
    notifyListeners();
  }

  Future<List<OperationEnAttente>> _lire(String? stocke) async {
    if (stocke == null) return const [];
    // Ancien format en clair : repris tel quel, puis réécrit chiffré.
    final brut = CoffreLocal.estChiffre(stocke)
        ? await _coffre.dechiffrer(stocke)
        : stocke;
    return brut == null
        ? const []
        : (jsonDecode(brut) as List)
              .map(
                (j) => OperationEnAttente.fromJson(
                  Map<String, dynamic>.from(j as Map),
                ),
              )
              .toList();
  }

  Future<void> _sauver() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _cle,
      await _coffre.chiffrer(
        jsonEncode(operations.map((o) => o.toJson()).toList()),
      ),
    );
    notifyListeners();
  }

  /// Envoie tout de suite ; sans réseau, met l'opération en file et renvoie `null`.
  Future<T?> envoyerOuDifferer<T>({
    required String libelle,
    required String chemin,
    required Map<String, dynamic> corps,
  }) async {
    final id = nouvelleCle();
    try {
      return await _api.post<T>(chemin, body: corps, idempotence: id);
    } on ApiException catch (e) {
      // Sans compte, rien ne garderait l'opération : l'erreur remonte à l'écran.
      if (!e.estReseau || _compteId == null) rethrow;
      operations.add(
        OperationEnAttente(
          id: id,
          libelle: libelle,
          chemin: chemin,
          corps: corps,
          creeLe: DateTime.now(),
        ),
      );
      await _sauver();
      return null;
    }
  }

  /// Rejoue les opérations en attente, dans l'ordre. Une erreur métier (4xx) est
  /// conservée sur l'opération pour que l'utilisateur la voie et la retire.
  /// Un envoi déjà lancé est attendu, pas doublé.
  Future<void> synchroniser() {
    if (_envoiEnCours != null) return _envoiEnCours!;
    if (operations.isEmpty) return Future.value();
    return _envoiEnCours = _envoyer().whenComplete(() => _envoiEnCours = null);
  }

  Future<void> _envoyer() async {
    synchronisation = true;
    echec = false;
    notifyListeners();
    for (final op in List.of(operations)) {
      try {
        await _api.post<dynamic>(op.chemin, body: op.corps, idempotence: op.id);
        operations.remove(op);
      } on ApiException catch (e) {
        // Session expirée : l'opération est intacte, elle repartira à la reconnexion.
        if (e.estReseau || e.status == 401) {
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
}
