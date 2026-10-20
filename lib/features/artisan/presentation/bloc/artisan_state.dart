import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/entities/artisan.dart';

abstract class ArtisanState {}

class ArtisanInitial extends ArtisanState {}

class ArtisanLoading extends ArtisanState {}

class ArtisanLoaded extends ArtisanState {
  final Artisan artisan;
  ArtisanLoaded(this.artisan);
}

/// Échec de la lecture : l'écran affiche l'erreur et « Réessayer ».
class ArtisanError extends ArtisanState {
  final Failure failure;
  String get message => failure.messageComplet;
  ArtisanError(this.failure);
}

/// Échec d'une action (ou d'une relecture) alors que l'écran est
/// affiché : un simple message, le contenu reste à l'écran.
class ArtisanActionError extends ArtisanState {
  final Failure failure;
  String get message => failure.messageComplet;
  ArtisanActionError(this.failure);
}

class ArtisanSuccess extends ArtisanState {
  final String message;
  ArtisanSuccess({this.message = 'Opération réussie'});
}

class ArtisanSupprime extends ArtisanState {
  final String message;
  ArtisanSupprime({this.message = 'Artisan supprimé'});
}
