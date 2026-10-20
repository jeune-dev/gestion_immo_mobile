import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/usecases/get_etats_des_lieux.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/presentation/pages/etat_des_lieux_detail_page.dart';

class ListeEtatsDesLieux extends StatelessWidget {
  final GlobalKey<ListePagineeState<EtatDesLieux>> cle;
  const ListeEtatsDesLieux({super.key, required this.cle});

  @override
  Widget build(BuildContext context) {
    return ListePaginee<EtatDesLieux>(
      key: cle,
      vide: 'Aucun état des lieux',
      iconeVide: Icons.fact_check_outlined,
      charger: (page) => sl<GetEtatsDesLieux>()(page: page),
      element: (context, e) => ListTile(
        title: Text(
            '${refs.libelle('type_etat_des_lieux', e.type)} · ${nomDe(e.locataire)}'),
        subtitle: Text(
            'Appartement ${e.appartementNumero ?? ''} · v${e.version ?? ''} · ${date(e.date)}'),
        trailing: Statut(
            FamilleStatut.etatDesLieux, 'statut_etat_des_lieux', e.statut),
        onTap: () async {
          await ouvrir(context, EtatDesLieuxDetailPage(id: e.id));
          cle.currentState?.recharger();
        },
      ),
    );
  }
}
