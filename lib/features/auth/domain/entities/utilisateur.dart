import 'package:equatable/equatable.dart';

import 'package:gestion_immo_mobile/core/config/user_role.dart';

/// Compte connecté (`GET /compte` → `user`).
class Utilisateur extends Equatable {
  final String id;
  final UserRole role;
  final String prenom;
  final String nom;
  final String? email;
  final String? telephone;
  final String? photoUrl;
  final String langue;
  final bool doitChangerMotDePasse;
  final bool doubleAuthentificationActive;

  String get nomComplet => '$prenom $nom'.trim();

  String get initiales =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();

  const Utilisateur({
    required this.id,
    required this.role,
    required this.prenom,
    required this.nom,
    this.email,
    this.telephone,
    this.photoUrl,
    this.langue = 'fr',
    this.doitChangerMotDePasse = false,
    this.doubleAuthentificationActive = false,
  });

  @override
  List<Object?> get props => [
    id,
    role,
    prenom,
    nom,
    email,
    telephone,
    photoUrl,
    langue,
    doitChangerMotDePasse,
    doubleAuthentificationActive,
  ];
}
