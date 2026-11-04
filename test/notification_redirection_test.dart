import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/features/abonnement/presentation/pages/abonnement_page.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/pages/caution_detail_page.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/pages/depenses_page.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeances_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/caution_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/charges_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/etat_des_lieux_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/incident_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/loyer_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/pages/etat_des_lieux_detail_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/facture_commune_detail_page.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incident_detail_page.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/entities/notification_app.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/widgets/ouvrir_notification.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/paiements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/rapprochements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/transactions_page.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/pages/travaux_detail_page.dart';

NotificationApp _n(String type, [Map<String, dynamic> data = const {}]) =>
    NotificationApp(id: '1', type: type, titre: 't', corps: 'c', donnees: data);

void main() {
  void verifier(
    bool locataire,
    String type,
    Map<String, dynamic> data,
    Type attendu,
  ) => expect(
    ecranNotification(_n(type, data), locataire: locataire).runtimeType,
    attendu,
    reason: '$type $data',
  );

  test('chaque type mène à sa page côté propriétaire', () {
    final cas = <(String, Map<String, dynamic>, Type)>[
      ('nouveau_paiement', {'rent_payment_id': 'x'}, PaiementDetailPage),
      (
        'nouveau_paiement',
        {'payment_transaction_id': 'x'},
        TransactionDetailPage,
      ),
      ('nouveau_paiement', {}, PaiementsPage),
      ('retard_loyer', {'lease_id': 'x'}, EcheancesPage),
      ('echeance', {}, EcheancesPage),
      ('facture', {'charge_invoice_id': 'x'}, FactureCommuneDetailPage),
      ('incident', {'incident_id': 'x'}, IncidentDetailPage),
      ('nouveau_travail', {'work_order_id': 'x'}, TravauxDetailPage),
      ('travail_termine', {'work_order_id': 'x'}, TravauxDetailPage),
      ('depense', {'expense_id': 'x'}, DepensesPage),
      ('caution', {'deposit_id': 'x'}, CautionDetailPage),
      ('etat_des_lieux', {'inspection_id': 'x'}, EtatDesLieuxDetailPage),
      ('rapprochement', {'reconciliation_entry_id': 'x'}, RapprochementsPage),
      ('abonnement', {'subscription_id': 'x'}, AbonnementPage),
    ];
    for (final (type, data, attendu) in cas) {
      verifier(false, type, data, attendu);
    }
  });

  test('chaque type mène à sa page côté locataire', () {
    final cas = <(String, Map<String, dynamic>, Type)>[
      (
        'nouveau_paiement',
        {'payment_transaction_id': 'x'},
        SuiviTransactionPage,
      ),
      (
        'nouveau_paiement',
        {'rent_payment_id': 'x', 'receipt_ids': 'r'},
        QuittancesPage,
      ),
      ('nouveau_paiement', {'rent_payment_id': 'x'}, LoyerPage),
      ('retard_loyer', {'lease_id': 'x'}, LoyerPage),
      ('facture', {'charge_ids': 'x'}, ChargesLocatairePage),
      ('incident', {'incident_id': 'x'}, IncidentLocatairePage),
      ('caution', {'deposit_id': 'x'}, CautionLocatairePage),
      ('etat_des_lieux', {'inspection_id': 'x'}, EtatDesLieuxLocatairePage),
    ];
    for (final (type, data, attendu) in cas) {
      verifier(true, type, data, attendu);
    }
  });

  test(
    'une information générale n’ouvre rien, un document et un message si',
    () {
      expect(notificationOuvrable(_n('systeme'), locataire: false), isFalse);
      expect(
        notificationOuvrable(
          _n('document_disponible', {'document_id': 'x'}),
          locataire: true,
        ),
        isTrue,
      );
      expect(
        notificationOuvrable(
          _n('nouveau_message', {'thread_id': 'x'}),
          locataire: false,
        ),
        isTrue,
      );
    },
  );
}
