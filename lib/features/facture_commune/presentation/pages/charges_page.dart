import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/get_charges_refacturees.dart';

/// Charges refacturées aux locataires (§ 15).
class ChargesPage extends StatefulWidget {
  const ChargesPage({super.key});

  @override
  State<ChargesPage> createState() => _ChargesPageState();
}

class _ChargesPageState extends State<ChargesPage> {
  String _statut = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charges refacturées')),
      body: Column(
        children: [
          Filtres(
            options: [
              ('', 'Toutes'),
              for (final o in refs.options('statut_charge')) (o.code, o.label)
            ],
            valeur: _statut,
            onChange: (v) => setState(() => _statut = v),
          ),
          Expanded(
            child: ListePaginee<ChargeRefacturee>(
              cle: _statut,
              vide: 'Aucune charge refacturée',
              charger: (page) => sl<GetChargesRefacturees>()(
                  page: page, statut: _statut.isEmpty ? null : _statut),
              element: (context, c) => ListTile(
                title:
                    Text('${nomDe(c.locataire)} · ${c.logementNumero ?? ''}'),
                subtitle: Text(
                    '${c.libelle ?? ''} · échéance ${date(c.dateEcheance)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Montant(c.montant,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Statut(FamilleStatut.charge, 'statut_charge', c.statut),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
