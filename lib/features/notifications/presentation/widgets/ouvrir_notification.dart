import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/abonnement/presentation/pages/abonnement_page.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/pages/caution_detail_page.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/pages/cautions_page.dart';
import 'package:gestion_immo_mobile/features/depense/presentation/pages/depenses_page.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/get_documents.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeances_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/caution_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/charges_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/demandes_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/etat_des_lieux_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/incident_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/loyer_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/suivi_transaction_page.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/pages/etat_des_lieux_detail_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/facture_commune_detail_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/factures_communes_page.dart';
import 'package:gestion_immo_mobile/features/home/presentation/pages/proprietaire/travaux_hub_page.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incident_detail_page.dart';
import 'package:gestion_immo_mobile/features/incident/presentation/pages/incidents_page.dart';
import 'package:gestion_immo_mobile/features/messagerie/presentation/pages/messagerie_page.dart';
import 'package:gestion_immo_mobile/features/notifications/domain/entities/notification_app.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/paiements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/rapprochements_page.dart';
import 'package:gestion_immo_mobile/features/paiement/presentation/pages/transactions_page.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/pages/travaux_detail_page.dart';

/// Page d'une notification selon son type et l'identifiant porté par `data` :
/// la fiche concernée, sinon la liste correspondante (`null` : aucune page).
Widget? ecranNotification(NotificationApp n, {required bool locataire}) {
  String? id(String cle) {
    final v = n.donnees[cle];
    return v == null || '$v'.isEmpty ? null : '$v';
  }

  final deposit = id('deposit_id');
  final incident = id('incident_id');
  final inspection = id('inspection_id');
  final facture = id('charge_invoice_id');
  final travail = id('work_order_id');
  final bail = id('lease_id');
  final paiement = id('rent_payment_id');
  final transaction = id('payment_transaction_id');

  if (locataire) {
    return switch (n.type) {
      'nouveau_paiement' when transaction != null => SuiviTransactionPage(
        id: transaction,
      ),
      'nouveau_paiement' when id('receipt_ids') != null => const QuittancesPage(
        espaceLocataire: true,
      ),
      'nouveau_paiement' || 'retard_loyer' || 'echeance' => const LoyerPage(),
      'facture' => const ChargesLocatairePage(),
      'incident' when incident != null => IncidentLocatairePage(id: incident),
      'incident' ||
      'nouveau_travail' ||
      'travail_termine' => const DemandesPage(),
      'caution' => const CautionLocatairePage(),
      'etat_des_lieux' when inspection != null => EtatDesLieuxLocatairePage(
        id: inspection,
      ),
      'etat_des_lieux' => const DemandesPage(),
      _ => null,
    };
  }
  return switch (n.type) {
    'nouveau_paiement' when paiement != null => PaiementDetailPage(
      id: paiement,
    ),
    'nouveau_paiement' when transaction != null => TransactionDetailPage(
      id: transaction,
    ),
    'nouveau_paiement' => const PaiementsPage(),
    'retard_loyer' ||
    'echeance' when bail != null => EcheancesPage(bailId: bail),
    'retard_loyer' || 'echeance' => const EcheancesPage(impayes: true),
    'facture' when facture != null => FactureCommuneDetailPage(id: facture),
    'facture' => const FacturesCommunesPage(),
    'incident' when incident != null => IncidentDetailPage(id: incident),
    'incident' => const IncidentsPage(),
    'nouveau_travail' ||
    'travail_termine' when travail != null => TravauxDetailPage(id: travail),
    'nouveau_travail' || 'travail_termine' => const TravauxHubPage(),
    'depense' => const DepensesPage(),
    'caution' when deposit != null => CautionDetailPage(id: deposit),
    'caution' => const CautionsPage(),
    'etat_des_lieux' when inspection != null => EtatDesLieuxDetailPage(
      id: inspection,
    ),
    'rapprochement' => const RapprochementsPage(),
    'abonnement' => const AbonnementPage(),
    _ => null,
  };
}

/// La notification mène-t-elle quelque part ?
bool notificationOuvrable(NotificationApp n, {required bool locataire}) =>
    n.filId != null ||
    n.documentId != null ||
    ecranNotification(n, locataire: locataire) != null;

/// Ouvre le message, le document ou la page d'une notification.
Future<void> ouvrirNotification(
  BuildContext context,
  NotificationApp n, {
  required bool locataire,
}) async {
  final filId = n.filId;
  if (n.type == 'nouveau_message' && filId != null) {
    return ouvrirFilDiscussion(context, filId, espaceLocataire: locataire);
  }
  final ecran = ecranNotification(n, locataire: locataire);
  if (ecran != null) {
    await ouvrir(context, ecran);
    return;
  }
  final documentId = n.documentId;
  if (documentId != null) await _ouvrirDocument(context, n, documentId);
}

/// Image ou PDF : le type vient de la liste des documents de l'entité, quand
/// la notification la précise.
Future<void> _ouvrirDocument(
  BuildContext context,
  NotificationApp n,
  String documentId,
) async {
  final type = n.donnees['entity_type'] as String?;
  final entite = n.donnees['entity_id'] as String?;
  if (type != null && entite != null) {
    final r = await sl<GetDocuments>()(type: type, id: entite);
    final doc = r
        .fold((_) => null, (p) => p.items)
        ?.where((d) => d.id == documentId)
        .firstOrNull;
    if (!context.mounted) return;
    if (doc != null) return ouvrirDocument(context, doc);
  }
  ouvrirFichierDocument(context, documentId, 'document.pdf');
}
