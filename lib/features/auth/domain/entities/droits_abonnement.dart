import 'package:equatable/equatable.dart';

/// Droits de l'abonnement du propriétaire (`GET /compte` → `abonnement`).
class DroitsAbonnement extends Equatable {
  /// Faux : abonnement échu ou suspendu, l'espace est en lecture seule (402).
  final bool actif;
  final String? statut;
  final String? plan;
  final String? finPeriode;

  const DroitsAbonnement(
      {required this.actif, this.statut, this.plan, this.finPeriode});

  @override
  List<Object?> get props => [actif, statut, plan, finPeriode];
}
