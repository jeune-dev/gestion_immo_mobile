import '../../domain/entities/notification_app.dart';

class NotificationModel extends NotificationApp {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.titre,
    required super.corps,
    super.creeLe,
    super.lueLe,
    super.donnees,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: '${json['id']}',
        type: json['type'] as String?,
        titre: json['title'] as String? ?? '',
        corps: json['body'] as String? ?? '',
        creeLe: json['created_at'] as String?,
        lueLe: json['read_at'] as String?,
        donnees: Map<String, dynamic>.from((json['data'] as Map?) ?? const {}),
      );
}
