import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/abonnement.dart';

class AbonnementModel {
  AbonnementModel._();

  static Quota? _quota(dynamic u) => u is Map
      ? Quota(
          utilise: entier(u['used']),
          max: u['max'] == null ? null : entier(u['max']))
      : null;

  static EtatAbonnement etat(Map<String, dynamic> a) {
    final abo = a['abonnement'] as Map?;
    final plan = a['plan'] as Map?;
    final usage = (a['usage'] as Map?) ?? const {};
    return EtatAbonnement(
      actif: a['actif'] == true,
      statut: abo?['status'] as String?,
      planCode: plan?['code'] as String?,
      planNom: plan?['name'] as String?,
      finPeriode: abo?['current_period_end'] as String?,
      immeubles: _quota(usage['buildings']),
      appartements: _quota(usage['apartments']),
      whatsappCeMois: _quota(usage['whatsapp_this_month']),
    );
  }

  static PlanAbonnement plan(Map<String, dynamic> p) => PlanAbonnement(
        code: '${p['code']}',
        nom: '${p['name'] ?? ''}',
        prix: entier(p['price']),
        periodeFacturation: p['billing_period'] as String?,
        maxImmeubles:
            p['max_buildings'] == null ? null : entier(p['max_buildings']),
        maxAppartements:
            p['max_apartments'] == null ? null : entier(p['max_apartments']),
        fonctionnalites:
            ((p['features'] as List?) ?? const []).map((f) => '$f').toList(),
      );

  static PaiementAbonnement paiement(Map<String, dynamic> p) =>
      PaiementAbonnement(
        reference: p['reference'] as String?,
        planNom: (p['plan'] as Map?)?['name'] as String?,
        mois: entier(p['months']),
        montant: nombreOuNull(p['amount']),
        statut: p['status'] as String?,
        date: (p['paid_at'] ?? p['created_at']) as String?,
        checkoutUrl: p['checkout_url'] as String?,
      );
}
