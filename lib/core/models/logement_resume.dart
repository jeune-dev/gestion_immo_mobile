import 'package:equatable/equatable.dart';

/// Appartement cité dans une autre ressource, avec son immeuble.
class LogementResume extends Equatable {
  final String id;
  final String numero;
  final String? immeubleId;
  final String? immeubleNom;

  const LogementResume(
      {required this.id,
      required this.numero,
      this.immeubleId,
      this.immeubleNom});

  static LogementResume? depuis(dynamic json) {
    if (json is! Map) return null;
    final immeuble = json['building'] as Map?;
    return LogementResume(
      id: '${json['id'] ?? ''}',
      numero: '${json['number'] ?? ''}',
      immeubleId: (immeuble?['id'] ?? json['building_id'])?.toString(),
      immeubleNom: immeuble?['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, numero, immeubleId, immeubleNom];
}
