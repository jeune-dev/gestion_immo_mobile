import '../format.dart';
import 'actions.dart';

/// Listes de l'API utilisées par les sélecteurs des formulaires.
class Sources {
  static final immeubles = SourceEntite(
    '/immeubles',
    libelle: (e) => '${e['name']}',
    sousTitre: (e) => [e['address'], e['city']].where((x) => x != null).join(', '),
  );

  static SourceEntite appartements({String? immeuble, String? statut}) => SourceEntite(
        '/appartements',
        query: {'building_id': immeuble, 'status': statut, 'tri': 'number'},
        libelle: (e) => 'Appartement ${e['number']}',
        sousTitre: (e) => '${(e['building'] as Map?)?['name'] ?? ''} · ${montant(e['rent_amount'] as num?)}',
      );

  static final locataires = SourceEntite(
    '/locataires',
    query: const {'tri': 'last_name'},
    libelle: (e) => nomComplet(e),
    sousTitre: (e) => '${e['phone'] ?? ''}',
  );

  static SourceEntite baux({String statut = 'actif'}) => SourceEntite(
        '/baux',
        query: {'status': statut},
        recherche: false,
        libelle: (e) => '${nomComplet(e['tenant'] as Map?)} · ${(e['apartment'] as Map?)?['number'] ?? ''}',
        sousTitre: (e) => '${e['reference']} · ${montant(e['rent_amount'] as num?)}',
      );

  static final artisans = SourceEntite(
    '/artisans',
    query: const {'is_active': true},
    libelle: (e) => '${e['name']}',
    sousTitre: (e) => '${e['phone'] ?? ''}',
  );

  static SourceEntite echeancesImpayees(String bail) => SourceEntite(
        '/echeances',
        query: {'lease_id': bail, 'impayes': true, 'tri': 'due_date'},
        recherche: false,
        libelle: (e) => '${e['label']}',
        sousTitre: (e) => 'Reste ${montant(entier(e['amount_due']) - entier(e['amount_paid']))} · échéance ${date(e['due_date'] as String?)}',
      );
}
