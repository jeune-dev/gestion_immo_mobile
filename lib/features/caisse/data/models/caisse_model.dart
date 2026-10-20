import 'package:gestion_immo_mobile/core/utils/format.dart';
import '../../domain/entities/caisse.dart';

class MouvementCaisseModel extends MouvementCaisse {
  const MouvementCaisseModel({
    required super.id,
    super.entree,
    super.libelle,
    super.date,
    super.categorie,
    super.moyen,
    super.montant,
    super.annule,
    super.manuel,
  });

  factory MouvementCaisseModel.fromJson(Map<String, dynamic> json) =>
      MouvementCaisseModel(
        id: '${json['id']}',
        entree: json['direction'] == 'entree',
        libelle: json['label'] as String?,
        date: json['occurred_on'] as String?,
        categorie: json['category'] as String?,
        moyen: json['method'] as String?,
        montant: nombreOuNull(json['amount']),
        annule: json['cancelled_at'] != null,
        manuel: json['source_type'] == null,
      );
}

class SyntheseCaisseModel extends SyntheseCaisse {
  const SyntheseCaisseModel(
      {super.entrees,
      super.sorties,
      super.solde,
      super.detailEntrees,
      super.detailSorties,
      super.cautionsDetenues});

  static List<TotalCategorie> _totaux(dynamic v) => listeJson(v)
      .map((d) => TotalCategorie(
          categorie: d['category'] as String?, total: nombreOuNull(d['total'])))
      .toList();

  factory SyntheseCaisseModel.fromJson(Map<String, dynamic> json) =>
      SyntheseCaisseModel(
        entrees: nombreOuNull(json['entrees']),
        sorties: nombreOuNull(json['sorties']),
        solde: nombreOuNull(json['solde']),
        detailEntrees: _totaux(json['detail_entrees']),
        detailSorties: _totaux(json['detail_sorties']),
        cautionsDetenues: nombreOuNull((json['cautions'] as Map?)?['solde']),
      );
}
