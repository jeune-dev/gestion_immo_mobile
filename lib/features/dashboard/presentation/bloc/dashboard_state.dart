import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/dashboard/domain/entities/tableau_de_bord.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final TableauDeBord tableauDeBord;
  DashboardLoaded(this.tableauDeBord);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class DashboardError extends DashboardState {
  final Failure failure;
  String get message => failure.messageComplet;
  DashboardError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class DashboardActionError extends DashboardState {
  final Failure failure;
  String get message => failure.messageComplet;
  DashboardActionError(this.failure);
}
