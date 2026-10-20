import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/features/documents/data/models/document_model.dart';
import '../../domain/entities/etat_des_lieux.dart';

class EtatDesLieuxModel extends EtatDesLieux {
  const EtatDesLieuxModel({
    required super.id,
    super.type,
    super.version,
    super.statut,
    super.realiseLe,
    super.soumisLe,
    super.creeLe,
    super.limiteReponse,
    super.accepteTacitement,
    super.contestation,
    super.compteurEau,
    super.compteurElectricite,
    super.nbCles,
    super.detailCles,
    super.observations,
    super.locataire,
    super.appartementNumero,
    super.pieces,
  });

  static ElementEdl _element(Map<String, dynamic> i) => ElementEdl(
        id: '${i['id']}',
        element: i['element'] as String?,
        precision: i['label'] as String?,
        etat: i['condition'] as String?,
        commentaire: i['comment'] as String?,
        photos: listeJson(i['photos'])
            .where((p) => p['document'] is Map)
            .map((p) => PhotoEdl(
                id: '${p['id']}',
                document: DocumentModel.fromJson(
                    Map<String, dynamic>.from(p['document'] as Map))))
            .toList(),
      );

  factory EtatDesLieuxModel.fromJson(Map<String, dynamic> json) =>
      EtatDesLieuxModel(
        id: '${json['id']}',
        type: json['type'] as String?,
        version: json['version'] == null ? null : entier(json['version']),
        statut: json['status'] as String?,
        realiseLe: json['performed_at'] as String?,
        soumisLe: json['submitted_at'] as String?,
        creeLe: json['created_at'] as String?,
        limiteReponse: json['response_deadline'] as String?,
        accepteTacitement: json['accepted_tacitly'] == true,
        contestation: json['contest_comment'] as String?,
        compteurEau: nombreOuNull(json['water_meter']),
        compteurElectricite: nombreOuNull(json['electricity_meter']),
        nbCles: json['keys_count'] == null ? null : entier(json['keys_count']),
        detailCles: json['keys_details'] as String?,
        observations: json['general_observations'] as String?,
        locataire: PersonneResume.depuis(json['tenant']),
        appartementNumero: (json['apartment'] as Map?)?['number']?.toString(),
        pieces: listeJson(json['rooms'])
            .map((r) => PieceEdl(
                id: '${r['id']}',
                nom: '${r['name'] ?? ''}',
                elements: listeJson(r['items']).map(_element).toList()))
            .toList(),
      );
}

class ComparaisonEdlModel extends ComparaisonEdl {
  const ComparaisonEdlModel(
      {super.elementsSortie,
      super.identiques,
      super.degrades,
      super.ameliores,
      super.absents,
      super.ecarts});

  factory ComparaisonEdlModel.fromJson(Map<String, dynamic> json) {
    final resume = (json['resume'] as Map?) ?? const {};
    return ComparaisonEdlModel(
      elementsSortie: entier(resume['elements_sortie']),
      identiques: entier(resume['identiques']),
      degrades: entier(resume['ecarts']),
      ameliores: entier(resume['ameliores']),
      absents: entier(resume['absents']),
      ecarts: listeJson(json['ecarts'])
          .map(
            (e) => EcartEdl(
              piece: e['piece'] as String?,
              element: e['element_libelle'] as String?,
              etatEntree:
                  (e['entree'] as Map?)?['condition_libelle'] as String?,
              etatSortie:
                  (e['sortie'] as Map?)?['condition_libelle'] as String?,
              commentaireSortie: (e['sortie'] as Map?)?['comment'] as String?,
            ),
          )
          .toList(),
    );
  }
}
