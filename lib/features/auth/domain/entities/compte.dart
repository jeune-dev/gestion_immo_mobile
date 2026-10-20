import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/config/user_role.dart';
import 'droits_abonnement.dart';
import 'espace_proprietaire.dart';
import 'utilisateur.dart';

/// Ce que `GET /compte` renvoie : l'utilisateur, et pour un propriétaire son espace et ses droits.
class Compte extends Equatable {
  final Utilisateur utilisateur;
  final EspaceProprietaire? espace;
  final DroitsAbonnement? abonnement;

  bool get estProprietaire => utilisateur.role == UserRole.proprietaire;
  bool get estLocataire => utilisateur.role == UserRole.locataire;

  /// Abonnement échu ou suspendu : l'espace propriétaire est en lecture seule (402).
  bool get lectureSeule =>
      estProprietaire && abonnement != null && !abonnement!.actif;

  const Compte({required this.utilisateur, this.espace, this.abonnement});

  @override
  List<Object?> get props => [utilisateur, espace, abonnement];
}
