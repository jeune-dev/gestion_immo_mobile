import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/network/api_client.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/choix_periode.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/immeuble/presentation/widgets/sources_immeuble.dart';
import 'package:gestion_immo_mobile/features/caisse/domain/entities/caisse.dart';
import 'package:gestion_immo_mobile/features/caisse/domain/usecases/ajouter_autre_revenu.dart';
import 'package:gestion_immo_mobile/features/caisse/domain/usecases/annuler_mouvement_caisse.dart';
import 'package:gestion_immo_mobile/features/caisse/domain/usecases/get_mouvements_caisse.dart';
import 'package:gestion_immo_mobile/features/caisse/domain/usecases/get_synthese_caisse.dart';

/// Caisse (§ 21) : entrées et sorties de la période, solde, détail par catégorie.
class CaissePage extends StatefulWidget {
  const CaissePage({super.key});

  @override
  State<CaissePage> createState() => _CaissePageState();
}

class _CaissePageState extends State<CaissePage> {
  Periode _periode = Periode.moisCourant();
  int _version = 0;

  void _rafraichir() => setState(() => _version++);

  Future<void> _autreRevenu() async {
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Autre revenu',
        initial: {'occurred_on': aujourdhui(), 'method': 'especes'},
        champs: [
          const Champ('label', 'Libellé',
              obligatoire: true,
              minLongueur: 2,
              maxLongueur: 200,
              indice: 'Ex. location de la terrasse'),
          const Champ('amount', 'Montant',
              type: TypeChamp.montant, obligatoire: true, min: 1),
          const Champ('method', 'Moyen',
              type: TypeChamp.selection,
              referentiel: 'mode_paiement',
              obligatoire: true),
          const Champ('occurred_on', 'Date',
              type: TypeChamp.date, obligatoire: true),
          Champ('building_id', 'Immeuble (facultatif)',
              type: TypeChamp.entite, entite: sourceImmeubles()),
        ],
        messageSucces: 'Revenu enregistré',
        envoyer: (c) async {
          (await sl<AjouterAutreRevenu>()(c, cle: cle)).ouLeve();
          return true;
        },
      ),
    );
    if (r != null && mounted) _rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AvecActions(
      onReussite: _rafraichir,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Caisse')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _autreRevenu,
            icon: const Icon(Icons.add),
            label: const Text('Autre revenu'),
          ),
          body: Column(
            children: [
              ChoixPeriode(
                  periode: _periode,
                  onChange: (v) => setState(() => _periode = v)),
              Expanded(
                child: ListePaginee<MouvementCaisse>(
                  cle: '${_periode.du}|${_periode.au}|$_version',
                  vide: 'Aucun mouvement sur la période',
                  entete: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _Synthese(
                        key:
                            ValueKey('${_periode.du}|${_periode.au}|$_version'),
                        periode: _periode),
                  ),
                  charger: (page) => sl<GetMouvementsCaisse>()(
                      page: page, du: _periode.du, au: _periode.au),
                  element: (context, m) => ListTile(
                    leading: Icon(
                        m.entree ? Icons.south_west : Icons.north_east,
                        color: m.entree ? p.succes : p.texteSecondaire),
                    title: Text(m.libelle ?? '',
                        style: m.annule
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough)
                            : null),
                    subtitle: Text(
                      '${date(m.date)} · ${refs.libelle('categorie_caisse', m.categorie)} · '
                      '${refs.libelle('mode_paiement', m.moyen)}${m.annule ? ' · annulé' : ''}',
                    ),
                    trailing: Text(
                      '${m.entree ? '+' : '−'} ${montant(m.montant)}',
                      style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: m.entree ? p.succes : null)
                          .merge(chiffresFixes),
                    ),
                    onLongPress: m.annule || !m.manuel
                        ? null
                        : () async {
                            final actions = context.read<ActionsCubit>();
                            final motif = await confirmer(
                              context,
                              titre: 'Annuler le mouvement',
                              message:
                                  'Seuls les mouvements saisis à la main peuvent être annulés.',
                              motif: true,
                              danger: true,
                            );
                            if (motif != null) {
                              actions.executer(
                                  sl<AnnulerMouvementCaisse>()(m.id, motif),
                                  succes: 'Mouvement annulé');
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Synthese extends StatefulWidget {
  final Periode periode;
  const _Synthese({super.key, required this.periode});

  @override
  State<_Synthese> createState() => _SyntheseState();
}

class _SyntheseState extends State<_Synthese> {
  late final Future<Either<Failure, SyntheseCaisse>> _synthese =
      sl<GetSyntheseCaisse>()(du: widget.periode.du, au: widget.periode.au);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FutureBuilder<Either<Failure, SyntheseCaisse>>(
      future: _synthese,
      builder: (context, s) {
        if (!s.hasData) {
          return const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()));
        }
        return s.data!.fold(
          (f) => VueErreur(f),
          (c) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChiffreCle(
                        libelle: 'Entrées',
                        valeur: montant(c.entrees),
                        icone: Icons.south_west),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChiffreCle(
                        libelle: 'Sorties',
                        valeur: montant(c.sorties),
                        icone: Icons.north_east),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Section(
                children: [
                  Ligne(
                    'Solde de la période',
                    null,
                    widget: Montant(
                      c.solde,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: (c.solde ?? 0) < 0 ? p.danger : p.succes),
                    ),
                  ),
                  for (final d in c.detailEntrees)
                    Ligne('+ ${refs.libelle('categorie_caisse', d.categorie)}',
                        montant(d.total)),
                  for (final d in c.detailSorties)
                    Ligne('− ${refs.libelle('categorie_caisse', d.categorie)}',
                        montant(d.total)),
                  const Divider(),
                  Ligne('Cautions détenues (hors revenus)',
                      montant(c.cautionsDetenues)),
                ],
              ),
              const SizedBox(height: AppTheme.espaceSm),
            ],
          ),
        );
      },
    );
  }
}
