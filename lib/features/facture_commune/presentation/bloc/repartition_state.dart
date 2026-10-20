import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';

abstract class RepartitionState {}

class RepartitionInitial extends RepartitionState {}

class RepartitionLoaded extends RepartitionState {
  final List<Appartement> appartements;

  /// Aperçu calculé par l'API ; `null` tant qu'il n'est pas demandé ou
  /// après un changement de saisie.
  final ApercuRepartition? apercu;
  final bool enCours;

  RepartitionLoaded({
    required this.appartements,
    this.apercu,
    this.enCours = false,
  });

  RepartitionLoaded copyWith({
    ApercuRepartition? apercu,
    bool effacerApercu = false,
    bool? enCours,
  }) =>
      RepartitionLoaded(
        appartements: appartements,
        apercu: effacerApercu ? null : apercu ?? this.apercu,
        enCours: enCours ?? false,
      );
}

/// Échec de la lecture des appartements.
class RepartitionError extends RepartitionState {
  final Failure failure;
  String get message => failure.messageComplet;
  RepartitionError(this.failure);
}

/// Échec de l'aperçu ou de la validation : la saisie reste à l'écran.
class RepartitionActionError extends RepartitionState {
  final Failure failure;
  String get message => failure.messageComplet;
  RepartitionActionError(this.failure);
}

class RepartitionSuccess extends RepartitionState {
  final String message;
  RepartitionSuccess({this.message = 'Facture répartie'});
}
