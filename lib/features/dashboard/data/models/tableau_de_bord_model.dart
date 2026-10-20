import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/tableau_de_bord.dart';

class TableauDeBordModel {
  TableauDeBordModel._();

  /// `GET /dashboard` → `dashboard` et `GET /dashboard/graphiques` → `graphiques`.
  static TableauDeBord depuis(Map<String, dynamic> d, Map<String, dynamic> g) {
    final p = (d['patrimoine'] as Map?) ?? const {};
    final l = (d['loyers'] as Map?) ?? const {};
    final t = (d['a_traiter'] as Map?) ?? const {};
    final debiteurs = (d['qui_n_a_pas_paye'] as Map?) ?? const {};
    return TableauDeBord(
      mois: '${d['mois'] ?? ''}',
      immeubles: entier(p['immeubles']),
      appartements: entier(p['appartements']),
      occupes: entier(p['occupes']),
      disponibles: entier(p['disponibles']),
      tauxOccupation: nombreOuNull(p['taux_occupation']),
      aRecevoir: nombreOuNull(l['a_recevoir']),
      encaisses: nombreOuNull(l['encaisses']),
      impayes: nombreOuNull(l['impayes']),
      depenses: nombreOuNull(d['depenses']),
      resultat: nombreOuNull(d['resultat']),
      preuvesAValider: entier(t['preuves_a_valider']),
      aRapprocher: entier(t['a_rapprocher']),
      facturesARepartir: entier(t['factures_a_repartir']),
      incidentsOuverts: entier(t['incidents_ouverts']),
      travauxEnCours: entier(d['travaux_en_cours']),
      totalDebiteurs: entier(debiteurs['total_debiteurs']),
      debiteurs: listeJson(debiteurs['locataires'])
          .map(
            (x) => Debiteur(
              locataire: PersonneResume(
                  id: '${x['tenant_id']}',
                  prenom: x['first_name'] as String? ?? '',
                  nom: x['last_name'] as String? ?? ''),
              immeuble: x['building_name'] as String?,
              appartement: x['apartment_number']?.toString(),
              depuis: x['plus_ancienne_echeance'] as String?,
              montant: nombreOuNull(x['montant']),
            ),
          )
          .toList(),
      revenusMensuels: listeJson(g['revenus_mensuels'])
          .map((r) => MontantMensuel('${r['mois']}', entier(r['total'])))
          .toList(),
      depensesMensuelles: {
        for (final x in listeJson(g['depenses_mensuelles']))
          '${x['mois']}': entier(x['total'])
      },
      depensesParCategorie: listeJson(g['depenses_par_categorie'])
          .map(
              (c) => DepenseCategorie('${c['name']}', nombreOuNull(c['total'])))
          .toList(),
    );
  }
}
