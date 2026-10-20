import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';

abstract class RepartitionEvent {}

/// Appartements de l'immeuble de la facture.
class LoadRepartition extends RepartitionEvent {
  final FactureCommune facture;
  LoadRepartition(this.facture);
}

/// Un choix a changé : l'aperçu affiché n'est plus valable.
class InvaliderApercuEvent extends RepartitionEvent {}

class PrevisualiserRepartitionEvent extends RepartitionEvent {
  final String factureId;
  final Map<String, dynamic> data;
  PrevisualiserRepartitionEvent(this.factureId, this.data);
}

class RepartirFactureEvent extends RepartitionEvent {
  final String factureId;
  final Map<String, dynamic> data;
  RepartirFactureEvent(this.factureId, this.data);
}
