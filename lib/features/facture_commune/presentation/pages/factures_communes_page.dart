import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/get_factures_communes.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/widgets/bandeau_a_repartir.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/widgets/formulaire_facture.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/facture_commune_detail_page.dart';

/// Factures communes (§ 16) : eau, électricité, gardiennage… et leur répartition (§ 17).
class FacturesCommunesPage extends StatefulWidget {
  final String statut;
  const FacturesCommunesPage({super.key, this.statut = ''});

  @override
  State<FacturesCommunesPage> createState() => _FacturesCommunesPageState();
}

class _FacturesCommunesPageState extends State<FacturesCommunesPage> {
  final _liste = GlobalKey<ListePagineeState<FactureCommune>>();
  late String _statut = widget.statut;

  /// Change à chaque retour d'une fiche : le bandeau « à répartir » se relit.
  int _version = 0;

  void _rafraichir() {
    _liste.currentState?.recharger();
    setState(() => _version++);
  }

  Future<void> _nouvelle() async {
    final f = await creerFactureCommune(context);
    if (f != null && mounted) {
      await ouvrir(context, FactureCommuneDetailPage(id: f.id));
      _rafraichir();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factures communes')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _nouvelle,
          icon: const Icon(Icons.add),
          label: const Text('Facture')),
      body: Column(
        children: [
          BandeauARepartir(
              cle: _version,
              onVoir: () => setState(() => _statut = 'brouillon')),
          Filtres(
            options: [
              ('', 'Toutes'),
              for (final o in refs.options('statut_facture_commune'))
                (o.code, o.label)
            ],
            valeur: _statut,
            onChange: (v) => setState(() => _statut = v),
          ),
          Expanded(
            child: ListePaginee<FactureCommune>(
              key: _liste,
              cle: _statut,
              vide: 'Aucune facture commune',
              iconeVide: Icons.water_drop_outlined,
              charger: (page) => sl<GetFacturesCommunes>()(
                  page: page, statut: _statut.isEmpty ? null : _statut),
              element: (context, f) => ListTile(
                title: Text(
                    '${refs.libelle('type_charge', f.typeCharge)} · ${f.immeubleNom ?? ''}'),
                subtitle: Text(
                    '${f.fournisseur ?? ''} · ${date(f.debutPeriode)} → ${date(f.finPeriode)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Montant(f.montant,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Pastille(
                      refs.libelle('statut_facture_commune', f.statut),
                      ton: f.statut == 'repartie'
                          ? TonStatut.succes
                          : f.brouillon
                              ? TonStatut.avertissement
                              : TonStatut.neutre,
                    ),
                  ],
                ),
                onTap: () async {
                  await ouvrir(context, FactureCommuneDetailPage(id: f.id));
                  _rafraichir();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
