import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/get_echeances.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeance_detail_page.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Échéances de loyer (§ 11) et impayés (§ 48 « Qui n'a pas payé ? »).
class EcheancesPage extends StatefulWidget {
  final bool impayes;
  final String? bailId;
  final String? locataireId;
  final String? titre;

  const EcheancesPage({
    super.key,
    this.impayes = false,
    this.bailId,
    this.locataireId,
    this.titre,
  });

  @override
  State<EcheancesPage> createState() => _EcheancesPageState();
}

class _EcheancesPageState extends State<EcheancesPage> {
  final _liste = GlobalKey<ListePagineeState<Echeance>>();
  late String _filtre = widget.impayes ? 'impayes' : '';

  Future<void> _ouvrir(BuildContext context, Echeance e) async {
    final modifiee = await ouvrir<bool>(context, EcheanceDetailPage(id: e.id));
    if (modifiee == true) _liste.currentState?.recharger();
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('impayes', 'Impayés'),
      ('', 'Toutes'),
      for (final o in refs.options('statut_echeance')) (o.code, o.label),
    ];
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(widget.titre ?? (widget.impayes ? 'Impayés' : 'Échéances')),
      ),
      body: Column(
        children: [
          Filtres(
            options: options,
            valeur: _filtre,
            onChange: (v) => setState(() => _filtre = v),
          ),
          Expanded(
            child: ListePaginee<Echeance>(
              key: _liste,
              cle: _filtre,
              vide: _filtre == 'impayes'
                  ? 'Aucun impayé. Tous les loyers sont à jour.'
                  : 'Aucune échéance',
              iconeVide: _filtre == 'impayes'
                  ? Icons.verified_outlined
                  : Icons.event_outlined,
              charger: (page) => sl<GetEcheances>()(
                page: page,
                bailId: widget.bailId,
                locataireId: widget.locataireId,
                impayes: _filtre == 'impayes',
                statut: _filtre == 'impayes' || _filtre.isEmpty
                    ? null
                    : _filtre,
              ),
              element: (context, e) => TuileOption(
                icone: Icons.event_outlined,
                titre: '${nomDe(e.locataire)} · ${e.logementNumero ?? ''}',
                detail: '${e.libelle ?? ''} · échéance ${date(e.dateEcheance)}',
                fin: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Montant(
                      e.reste > 0 && e.statut != 'annule'
                          ? e.reste
                          : e.montantDu,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: e.statut == 'en_retard'
                            ? context.palette.danger
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppTheme.espaceXs),
                    Statut(FamilleStatut.echeance, 'statut_echeance', e.statut),
                  ],
                ),
                onTap: () => _ouvrir(context, e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
