import 'package:equatable/equatable.dart';

/// Personne citée dans une autre ressource (locataire d'un bail, d'un paiement…).
class PersonneResume extends Equatable {
  final String id;
  final String prenom;
  final String nom;
  final String? telephone;

  const PersonneResume(
      {required this.id,
      required this.prenom,
      required this.nom,
      this.telephone});

  String get nomComplet {
    final s = '$prenom $nom'.trim();
    return s.isEmpty ? '—' : s;
  }

  String get initiales {
    final s =
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  static PersonneResume? depuis(dynamic json) => json is Map
      ? PersonneResume(
          id: '${json['id'] ?? ''}',
          prenom: json['first_name'] as String? ?? '',
          nom: json['last_name'] as String? ?? '',
          telephone: json['phone'] as String?,
        )
      : null;

  @override
  List<Object?> get props => [id, prenom, nom, telephone];
}

/// « — » quand la personne est absente.
String nomDe(PersonneResume? p) => p?.nomComplet ?? '—';
