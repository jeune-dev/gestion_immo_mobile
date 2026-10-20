import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/entities/travaux.dart';
import 'package:gestion_immo_mobile/features/travaux/domain/usecases/get_travaux_liste.dart';
import 'package:gestion_immo_mobile/features/travaux/presentation/pages/travaux_detail_page.dart';

class ListeTravaux extends StatefulWidget {
  final GlobalKey<ListePagineeState<Travaux>> cle;
  const ListeTravaux({super.key, required this.cle});

  @override
  State<ListeTravaux> createState() => _ListeTravauxState();
}

class _ListeTravauxState extends State<ListeTravaux> {
  String _statut = 'ouverts';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Filtres(
          options: [
            ('ouverts', 'En cours'),
            ('', 'Tous'),
            for (final o in refs.options('statut_travaux')) (o.code, o.label)
          ],
          valeur: _statut,
          onChange: (v) => setState(() => _statut = v),
        ),
        Expanded(
          child: ListePaginee<Travaux>(
            key: widget.cle,
            cle: _statut,
            vide: 'Aucun chantier',
            iconeVide: Icons.handyman_outlined,
            charger: (page) async {
              final r = await sl<GetTravauxListe>()(
                  page: page,
                  statut:
                      _statut == 'ouverts' || _statut.isEmpty ? null : _statut);
              if (_statut != 'ouverts') return r;
              // « En cours » : tout ce qui n'est ni terminé ni annulé
              return r.map((p) => p.filtrer((t) => !t.ferme));
            },
            element: (context, t) => ListTile(
              title: Text('${t.reference ?? ''} · ${t.titre ?? ''}'),
              subtitle: Text(
                [
                  t.immeubleNom,
                  if (t.appartementNumero != null)
                    'Appart. ${t.appartementNumero}',
                  refs.libelle('priorite', t.priorite),
                ].whereType<String>().join(' · '),
              ),
              trailing:
                  Statut(FamilleStatut.travaux, 'statut_travaux', t.statut),
              onTap: () async {
                await ouvrirTravaux(context, t.id);
                widget.cle.currentState?.recharger();
              },
            ),
          ),
        ),
      ],
    );
  }
}
