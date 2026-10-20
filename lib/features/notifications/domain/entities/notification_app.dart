import 'package:equatable/equatable.dart';

/// Notification interne (§ 27) : paiement, retard, incident, travaux, document…
class NotificationApp extends Equatable {
  final String id;
  final String? type;
  final String titre;
  final String corps;
  final String? creeLe;
  final String? lueLe;

  bool get lue => lueLe != null;

  const NotificationApp(
      {required this.id,
      required this.type,
      required this.titre,
      required this.corps,
      this.creeLe,
      this.lueLe});

  @override
  List<Object?> get props => [id, type, titre, corps, creeLe, lueLe];
}
