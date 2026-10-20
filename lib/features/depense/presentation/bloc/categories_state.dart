import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/depense/domain/entities/depense.dart';

abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<CategorieDepense> categories;
  CategoriesLoaded(this.categories);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class CategoriesError extends CategoriesState {
  final Failure failure;
  String get message => failure.messageComplet;
  CategoriesError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class CategoriesActionError extends CategoriesState {
  final Failure failure;
  String get message => failure.messageComplet;
  CategoriesActionError(this.failure);
}

class CategoriesSuccess extends CategoriesState {
  final String message;
  CategoriesSuccess({this.message = 'Opération réussie'});
}
