import '../../domain/entities/session_appareil.dart';

class SessionAppareilModel extends SessionAppareil {
  const SessionAppareilModel(
      {required super.id,
      super.nomAppareil,
      super.plateforme,
      super.derniereUtilisation,
      super.courante});

  factory SessionAppareilModel.fromJson(Map<String, dynamic> json) =>
      SessionAppareilModel(
        id: '${json['id']}',
        nomAppareil: json['device_name'] as String?,
        plateforme: json['platform'] as String?,
        derniereUtilisation: json['last_used_at'] as String?,
        courante: json['current'] == true,
      );
}

class SecretMfaModel extends SecretMfa {
  const SecretMfaModel({required super.secret, required super.otpauthUrl});

  factory SecretMfaModel.fromJson(Map<String, dynamic> json) => SecretMfaModel(
      secret: '${json['secret']}', otpauthUrl: '${json['otpauth_url']}');
}
