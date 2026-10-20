import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/formulaire.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/etat_des_lieux/domain/entities/etat_des_lieux.dart';
import 'package:gestion_immo_mobile/features/incident/domain/entities/incident.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_logements_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_etats_des_lieux.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_mes_incidents.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/signaler_probleme.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/etat_des_lieux_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/incident_locataire_page.dart';

/// « Signaler un problème » et « Mes demandes » (§ 22, § 28) ; états des lieux à valider (§ 52).
class DemandesPage extends StatefulWidget {
  const DemandesPage({super.key});

  @override
  State<DemandesPage> createState() => _DemandesPageState();
}

class _DemandesPageState extends State<DemandesPage>
    with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  final _incidents = GlobalKey<ListePagineeState<Incident>>();

  /// Baux actifs du locataire : avec plusieurs locations en cours, l'API exige
  /// le `lease_id` du logement concerné (sinon 422 BAIL_A_PRECISER).
  Future<List<OptionRef>> _logementsActifs() async {
    final r = await sl<GetLogementsLocataire>()();
    // Hors ligne sans cache : l'API tranchera (bail unique) à la synchronisation
    return r.fold(
      (_) => const [],
      (logements) => [
        for (final b in logements.where((b) => b.actif))
          OptionRef(
              b.bailId,
              [
                b.immeubleNom,
                if (b.appartementNumero != null)
                  'Appartement ${b.appartementNumero}'
              ].whereType<String>().join(' · ')),
      ],
    );
  }

  Future<void> _signaler() async {
    final logements = await _logementsActifs();
    if (!mounted) return;
    final r = await EcranFormulaire.ouvrir<Object>(
      context,
      EcranFormulaire(
        titre: 'Signaler un problème',
        intro: const Text(
            'Décrivez le problème : votre propriétaire est prévenu immédiatement. Vous pourrez ajouter des photos ensuite.'),
        champs: [
          if (logements.length > 1)
            Champ('lease_id', 'Logement concerné',
                type: TypeChamp.selection,
                options: logements,
                obligatoire: true),
          const Champ('category', 'Type de problème',
              type: TypeChamp.selection,
              referentiel: 'categorie_incident',
              obligatoire: true),
          const Champ('title', 'En quelques mots',
              obligatoire: true,
              maxLongueur: 150,
              indice: 'Ex. Fuite sous l’évier'),
          const Champ('description', 'Description',
              type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 5000),
        ],
        libelleEnvoi: 'Envoyer',
        envoyer: (c) async =>
            (await sl<SignalerProbleme>()(c)).ouLeve() ?? 'differe',
      ),
    );
    if (r == null || !mounted) return;
    if (r == 'differe') {
      return afficherSucces(context,
          'Hors ligne : votre signalement sera envoyé au retour du réseau.');
    }
    afficherSucces(context, 'Signalement envoyé');
    _incidents.currentState?.recharger();
    if (r is Incident) await ouvrir(context, IncidentLocatairePage(id: r.id));
    _incidents.currentState?.recharger();
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes'),
        bottom: TabBar(
          controller: _onglets,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(text: 'Problèmes signalés'),
            Tab(text: 'États des lieux'),
          ],
        ),
      ),
      floatingActionButton: _onglets.index == 0
          ? FloatingActionButton.extended(
              onPressed: _signaler,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Signaler un problème'),
            )
          : null,
      body: TabBarView(
        controller: _onglets,
        children: [
          ListePaginee<Incident>(
            key: _incidents,
            vide: 'Aucun problème signalé',
            iconeVide: Icons.build_circle_outlined,
            charger: (page) => sl<GetMesIncidents>()(page: page),
            element: (context, i) => ListTile(
              title: Text(i.titre ?? ''),
              subtitle: Text(
                  '${i.reference ?? ''} · ${refs.libelle('categorie_incident', i.categorie)} · ${ilYa(i.creeLe)}'),
              trailing:
                  Statut(FamilleStatut.incident, 'statut_incident', i.statut),
              onTap: () async {
                await ouvrir(context, IncidentLocatairePage(id: i.id));
                _incidents.currentState?.recharger();
              },
            ),
          ),
          ListePaginee<EtatDesLieux>(
            vide: 'Aucun état des lieux',
            iconeVide: Icons.fact_check_outlined,
            charger: (page) => sl<GetMesEtatsDesLieux>()(page: page),
            element: (context, e) => ListTile(
              title: Text(
                  '${refs.libelle('type_etat_des_lieux', e.type)} · version ${e.version ?? ''}'),
              subtitle: Text(
                e.statut == 'soumis'
                    ? 'À accepter ou contester avant le ${dateHeure(e.limiteReponse)}'
                    : date(e.realiseLe ?? e.soumisLe),
              ),
              trailing: Statut(FamilleStatut.etatDesLieux,
                  'statut_etat_des_lieux', e.statut),
              onTap: () => ouvrir(context, EtatDesLieuxLocatairePage(id: e.id)),
            ),
          ),
        ],
      ),
    );
  }
}
