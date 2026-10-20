import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/rapports.dart';

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};
String _nom(Map<String, dynamic> p) =>
    '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

/// Lecture des rapports de l'API (`GET /rapports/:type` → `rapport`).
class RapportsModel {
  RapportsModel._();

  static RapportFinancier financier(Map<String, dynamic> r) {
    final rev = _m(r['revenus']);
    final dep = _m(r['depenses']);
    final imp = _m(r['impayes']);
    final ch = _m(r['charges']);
    return RapportFinancier(
      loyers: nombreOuNull(rev['loyers']),
      chargesRecuperees: nombreOuNull(rev['charges_recuperees']),
      autresRevenus: nombreOuNull(rev['autres_revenus']),
      totalRevenus: nombreOuNull(rev['total']),
      totalDepenses: nombreOuNull(dep['total']),
      beneficeNet: nombreOuNull(r['benefice_net']),
      impayesDate: imp['date'] as String?,
      impayesMontant: nombreOuNull(imp['montant']),
      impayesEcheances: entier(imp['echeances']),
      impayesLocataires: entier(imp['locataires']),
      depensesParCategorie: listeJson(dep['par_categorie'])
          .map((c) => LigneMontant('${c['name']}', nombreOuNull(c['total'])))
          .toList(),
      nombreFactures: entier(ch['nombre_factures']),
      facturesTotal: nombreOuNull(ch['factures_total']),
      chargesRefacturees: nombreOuNull(ch['refacturees_locataires']),
      chargesRecupereesLocataires: nombreOuNull(ch['recuperees_locataires']),
      resteARecouvrer: nombreOuNull(ch['reste_a_recouvrer']),
      aChargeProprietaire: nombreOuNull(ch['a_charge_proprietaire']),
      parImmeuble: listeJson(r['par_immeuble'])
          .map(
            (b) => FinancierImmeuble(
              nom: '${b['name']}',
              revenus: nombreOuNull(_m(b['revenus'])['total']),
              depenses: nombreOuNull(b['depenses']),
              impayes: nombreOuNull(b['impayes']),
              beneficeNet: nombreOuNull(b['benefice_net']),
            ),
          )
          .toList(),
    );
  }

  static RapportImmobilier immobilier(Map<String, dynamic> r) {
    final l = _m(r['loyers']);
    return RapportImmobilier(
      immeubles: entier(r['immeubles']),
      appartements: entier(r['appartements']),
      occupes: entier(r['occupes']),
      disponibles: entier(r['disponibles']),
      enTravaux: entier(r['en_travaux']),
      tauxOccupation: nombreOuNull(r['taux_occupation']),
      tauxOccupationPeriode: nombreOuNull(r['taux_occupation_periode']),
      loyerMensuelOccupes: nombreOuNull(l['loyer_mensuel_occupes']),
      loyerMoyen: nombreOuNull(l['loyer_moyen']),
      loyerPotentiel: nombreOuNull(l['loyer_potentiel']),
      manqueAGagner: nombreOuNull(l['manque_a_gagner_vacance']),
      parImmeuble: listeJson(r['par_immeuble'])
          .map(
            (b) => OccupationImmeuble(
              nom: '${b['name']}',
              ville: b['city'] as String?,
              appartements: entier(b['appartements']),
              occupes: entier(b['occupes']),
              tauxOccupation: nombreOuNull(b['taux_occupation']),
            ),
          )
          .toList(),
    );
  }

  static List<MouvementLocataire> _mouvements(dynamic v) => listeJson(v)
      .map(
        (b) => MouvementLocataire(
          nom: _nom(b),
          immeuble: b['building_name'] as String?,
          appartement: b['apartment_number']?.toString(),
          date: b['date'] as String?,
        ),
      )
      .toList();

  static RapportLocataires locataires(Map<String, dynamic> r) {
    final arrivees = _m(r['arrivees']);
    final departs = _m(r['departs']);
    final imp = _m(r['impayes']);
    return RapportLocataires(
      actifs: entier(r['actifs']),
      nombreArrivees: entier(arrivees['nombre']),
      nombreDeparts: entier(departs['nombre']),
      impayesTotal: nombreOuNull(imp['total']),
      enImpaye: listeJson(imp['locataires'])
          .map(
            (t) => LocataireEnImpaye(
              nom: _nom(t),
              echeances: entier(t['echeances']),
              depuis: t['plus_ancienne_echeance'] as String?,
              montant: nombreOuNull(t['montant']),
            ),
          )
          .toList(),
      arrivees: _mouvements(arrivees['baux']),
      departs: _mouvements(departs['baux']),
    );
  }

  static RapportTravaux travaux(Map<String, dynamic> r) {
    final couts = _m(r['couts']);
    return RapportTravaux(
      crees: entier(r['crees_sur_periode']),
      termines: entier(r['termines']),
      enCours: entier(r['en_cours']),
      enAttente: entier(r['en_attente']),
      annules: entier(r['annules']),
      coutEstime: nombreOuNull(couts['estime']),
      coutReel: nombreOuNull(couts['reel']),
      depensesLiees: nombreOuNull(couts['depenses_liees']),
      parCategorie: listeJson(r['par_categorie'])
          .map(
            (c) => TravauxParCategorie(
              categorie: c['category'] as String?,
              nombre: entier(c['nombre']),
              termines: entier(c['termines']),
              coutReel: nombreOuNull(c['cout_reel']),
            ),
          )
          .toList(),
    );
  }

  static LigneRentabilite rentabilite(Map<String, dynamic> a) =>
      LigneRentabilite(
        rang: a['rang'] == null ? null : entier(a['rang']),
        immeuble: a['building_name'] as String?,
        appartement: a['apartment_number']?.toString(),
        revenus: nombreOuNull(a['revenus']),
        depenses: nombreOuNull(a['depenses']),
        tauxOccupation: nombreOuNull(a['taux_occupation']),
        resultatNet: nombreOuNull(a['resultat_net']),
      );
}
