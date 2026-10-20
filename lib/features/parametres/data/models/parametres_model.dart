import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/parametres.dart';

class ParametresModel {
  ParametresModel._();

  static int? _entier(dynamic v) => v == null ? null : entier(v);

  /// `GET /parametres` → `{ owner, settings }`.
  static ParametresProprietaire depuis(Map<String, dynamic> r) {
    final o = (r['owner'] as Map?) ?? const {};
    final s = (r['settings'] as Map?) ?? const {};
    return ParametresProprietaire(
      espace: EspaceBailleur(
        nomAffiche: o['display_name'] as String?,
        societe: o['company_name'] as String?,
        telephone: o['phone'] as String?,
        email: o['email'] as String?,
        adresse: o['address'] as String?,
        ville: o['city'] as String?,
      ),
      reglages: ReglagesGestion(
        relances:
            ((s['reminder_offsets'] as List?) ?? const []).map(entier).toList(),
        preavisEcheance: _entier(s['schedule_notice_days']),
        delaiGrace: _entier(s['late_grace_days']),
        delaiReponseEdl: _entier(s['inspection_response_days']),
        delaiRestitutionCaution: _entier(s['deposit_refund_days']),
        politiqueEdlEntree: s['entry_inspection_policy'] as String?,
        ordreCanaux: ((s['channel_order'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        strategieNotification: s['notification_strategy'] as String?,
      ),
    );
  }
}
