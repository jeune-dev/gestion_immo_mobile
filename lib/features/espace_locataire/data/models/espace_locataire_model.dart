import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/echeance/data/models/echeance_model.dart';
import '../../domain/entities/espace_locataire.dart';

class EspaceLocataireModel {
  EspaceLocataireModel._();

  /// Bail tel que renvoyé par `/locataire/logement` (ou dans `homes[].lease`).
  static LogementLocataire logement(Map<String, dynamic> bail,
      {Map<String, dynamic>? accueil}) {
    final app = (bail['apartment'] as Map?) ?? const {};
    final immeuble = (app['building'] as Map?) ?? const {};
    final owner = (bail['owner'] as Map?) ?? const {};
    final prochaine = accueil?['next_schedule'];
    return LogementLocataire(
      bailId: '${bail['id']}',
      statutBail: bail['status'] as String?,
      appartementNumero: app['number']?.toString(),
      appartementType: app['type'] as String?,
      immeubleNom: immeuble['name'] as String?,
      immeubleAdresse: immeuble['address'] as String?,
      ville: immeuble['city'] as String?,
      loyer: entier(bail['rent_amount']),
      charges: entier(bail['charges_amount']),
      periodicite: bail['periodicity'] as String?,
      proprietaireNom: owner['display_name'] as String?,
      proprietaireTelephone: owner['phone'] as String?,
      prochaineEcheance: prochaine is Map
          ? EcheanceModel.fromJson(
              {...Map<String, dynamic>.from(prochaine), 'lease_id': bail['id']})
          : null,
      montantEnRetard: entier(accueil?['amount_overdue']),
      montantDu: entier(accueil?['amount_due']),
    );
  }

  static MoyensPaiementLocataire moyens(Map<String, dynamic> m) =>
      MoyensPaiementLocataire(
        integres:
            ((m['integre'] as List?) ?? const []).map((e) => '$e').toList(),
        preuves: listeJson(m['preuve'])
            .map((p) => MoyenPreuve(
                portefeuille: '${p['wallet']}',
                libelle: p['label'] as String?,
                numero: p['account_number'] as String?))
            .toList(),
        beneficiaire: m['beneficiaire'] as String?,
        especes: m['especes'] == true,
      );
}
