import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/entities/quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/usecases/get_quittances.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/widgets/tuile_quittance.dart';

/// Quittances (§ 13) : consulter, télécharger, partager.
class QuittancesPage extends StatelessWidget {
  /// Quittances du locataire connecté plutôt que celles du propriétaire.
  final bool espaceLocataire;
  const QuittancesPage({super.key, this.espaceLocataire = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quittances')),
      body: ListePaginee<Quittance>(
        vide: 'Aucune quittance',
        iconeVide: Icons.description_outlined,
        charger: (page) =>
            sl<GetQuittances>()(page: page, espaceLocataire: espaceLocataire),
        element: (context, q) =>
            TuileQuittance(q: q, espaceLocataire: espaceLocataire),
      ),
    );
  }
}
