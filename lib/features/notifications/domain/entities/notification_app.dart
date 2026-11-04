import 'package:equatable/equatable.dart';

/// Notification interne (§ 27) : paiement, retard, incident, travaux, document…
class NotificationApp extends Equatable {
  final String id;
  final String? type;
  final String titre;
  final String corps;
  final String? creeLe;
  final String? lueLe;

  /// Identifiants de ce que la notification concerne (`data` de l'API).
  final Map<String, dynamic> donnees;

  String? get filId => donnees['thread_id'] as String?;
  String? get documentId => donnees['document_id'] as String?;

  bool get lue => lueLe != null;

  const NotificationApp({
    required this.id,
    required this.type,
    required this.titre,
    required this.corps,
    this.creeLe,
    this.lueLe,
    this.donnees = const {},
  });

  @override
  List<Object?> get props => [id, type, titre, corps, creeLe, lueLe, donnees];
}
