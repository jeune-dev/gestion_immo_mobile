import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/caution/domain/entities/caution.dart';
import 'package:gestion_immo_mobile/features/caution/domain/usecases/get_cautions.dart';
import 'package:gestion_immo_mobile/features/caution/presentation/pages/caution_detail_page.dart';

/// Cautions (§ 55) : versées, détenues, retenues (justifiées), restituées ou en litige.
class CautionsPage extends StatefulWidget {
  const CautionsPage({super.key});

  @override
  State<CautionsPage> createState() => _CautionsPageState();
}

class _CautionsPageState extends State<CautionsPage> {
  final _liste = GlobalKey<ListePagineeState<Caution>>();
  String _statut = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cautions')),
      body: Column(
        children: [
          Filtres(
            options: [
              ('', 'Toutes'),
              for (final o in refs.options('statut_caution')) (o.code, o.label)
            ],
            valeur: _statut,
            onChange: (v) => setState(() => _statut = v),
          ),
          Expanded(
            child: ListePaginee<Caution>(
              key: _liste,
              cle: _statut,
              vide: 'Aucune caution',
              iconeVide: Icons.savings_outlined,
              charger: (page) => sl<GetCautions>()(
                  page: page, statut: _statut.isEmpty ? null : _statut),
              element: (context, c) => ListTile(
                title: Text('${nomDe(c.locataire)} · ${c.bailReference ?? ''}'),
                subtitle:
                    Text('Reçu ${montant(c.recue)} sur ${montant(c.attendue)}'),
                trailing:
                    Statut(FamilleStatut.caution, 'statut_caution', c.statut),
                onTap: () async {
                  await ouvrir(context, CautionDetailPage(id: c.id));
                  _liste.currentState?.recharger();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
