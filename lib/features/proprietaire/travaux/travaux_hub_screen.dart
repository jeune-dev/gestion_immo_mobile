import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/formulaire.dart';
import '../../../core/widgets/navigation.dart';
import '../../../core/widgets/sources.dart';
import '../../../theme/statuts.dart';
import 'artisans_screen.dart';
import 'etats_des_lieux.dart';
import 'incidents_screen.dart';
import 'travaux_screen.dart';

/// Onglet « Travaux » : chantiers, incidents signalés, artisans, états des lieux.
class TravauxHubScreen extends StatefulWidget {
  const TravauxHubScreen({super.key});

  @override
  State<TravauxHubScreen> createState() => _TravauxHubScreenState();
}

class _TravauxHubScreenState extends State<TravauxHubScreen> with SingleTickerProviderStateMixin {
  late final _onglets = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));
  final _cles = List.generate(4, (_) => GlobalKey<ListePagineeState>());

  Future<void> _ajouter() async {
    final i = _onglets.index;
    final r = await switch (i) {
      0 => FormulairesTravaux.travaux(context),
      1 => FormulairesTravaux.incident(context),
      2 => FormulairesTravaux.artisan(context),
      _ => EtatsDesLieux.creer(context),
    };
    if (r != null) _cles[i].currentState?.recharger();
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travaux'),
        bottom: TabBar(
          controller: _onglets,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: fg,
          unselectedLabelColor: fg?.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [Tab(text: 'Chantiers'), Tab(text: 'Incidents'), Tab(text: 'Artisans'), Tab(text: 'États des lieux')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: Text(['Travaux', 'Incident', 'Artisan', 'État des lieux'][_onglets.index]),
      ),
      body: TabBarView(controller: _onglets, children: [
        ListeTravaux(cle: _cles[0]),
        ListeIncidents(cle: _cles[1]),
        ListeArtisans(cle: _cles[2]),
        ListeEtatsDesLieux(cle: _cles[3]),
      ]),
    );
  }
}

/// Formulaires du module travaux (§ 18–24).
class FormulairesTravaux {
  static Future<Map?> travaux(BuildContext context, {Map<String, dynamic>? existant}) {
    final cle = nouvelleCle();
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Nouveaux travaux' : 'Modifier les travaux',
        initial: existant ?? const {'priority': 'normale', 'status': 'signale'},
        champs: [
          if (existant == null) Champ('building_id', 'Immeuble', type: TypeChamp.entite, obligatoire: true, entite: Sources.immeubles),
          const Champ('title', 'Intitulé', obligatoire: true, maxLongueur: 150, indice: 'Ex. Fuite salle de bain'),
          const Champ('category', 'Catégorie', type: TypeChamp.selection, referentiel: 'categorie_travaux', obligatoire: true),
          const Champ('priority', 'Priorité', type: TypeChamp.selection, referentiel: 'priorite', obligatoire: true),
          Champ('apartment_id', 'Appartement (facultatif)', type: TypeChamp.entite, entite: Sources.appartements()),
          const Champ('description', 'Description', type: TypeChamp.multiligne, maxLongueur: 5000),
          const Champ('estimated_amount', 'Coût estimé', type: TypeChamp.montant, nullable: true),
          Champ('contractor_id', 'Artisan', type: TypeChamp.entite, entite: Sources.artisans),
          const Champ('scheduled_for', 'Date prévue', type: TypeChamp.date),
        ],
        messageSucces: existant == null ? 'Travaux créés' : 'Travaux modifiés',
        envoyer: (c) async => existant == null
            ? (await api.post<Map<String, dynamic>>('/travaux', body: c, idempotence: cle))['work_order']
            : (await api.patch<Map<String, dynamic>>('/travaux/${existant['id']}', body: c))['work_order'],
      ),
    );
  }

  static Future<Map?> incident(BuildContext context) {
    final cle = nouvelleCle();
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Nouvel incident',
        champs: [
          Champ('building_id', 'Immeuble', type: TypeChamp.entite, obligatoire: true, entite: Sources.immeubles),
          Champ('apartment_id', 'Appartement (facultatif)', type: TypeChamp.entite, entite: Sources.appartements()),
          const Champ('category', 'Catégorie', type: TypeChamp.selection, referentiel: 'categorie_incident', obligatoire: true),
          const Champ('title', 'Titre', obligatoire: true, maxLongueur: 150),
          const Champ('description', 'Description', type: TypeChamp.multiligne, obligatoire: true, maxLongueur: 5000),
        ],
        messageSucces: 'Incident enregistré',
        envoyer: (c) async => (await api.post<Map<String, dynamic>>('/incidents', body: c, idempotence: cle))['incident'],
      ),
    );
  }

  static Future<Map?> artisan(BuildContext context, {Map<String, dynamic>? existant}) {
    final cle = nouvelleCle();
    return EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: existant == null ? 'Nouvel artisan' : "Modifier l'artisan",
        initial: existant ?? const {},
        champs: const [
          Champ('name', 'Nom', obligatoire: true, maxLongueur: 150),
          Champ('trade', 'Métier', type: TypeChamp.selection, referentiel: 'metier_artisan', obligatoire: true),
          Champ('phone', 'Téléphone', type: TypeChamp.telephone),
          Champ('email', 'E-mail', type: TypeChamp.email),
          Champ('notes', 'Notes', type: TypeChamp.multiligne, maxLongueur: 2000),
        ],
        messageSucces: existant == null ? 'Artisan ajouté' : 'Artisan modifié',
        envoyer: (c) async => existant == null
            ? (await api.post<Map<String, dynamic>>('/artisans', body: c, idempotence: cle))['contractor']
            : (await api.patch<Map<String, dynamic>>('/artisans/${existant['id']}', body: c))['contractor'],
      ),
    );
  }
}

class ListeTravaux extends StatefulWidget {
  const ListeTravaux({super.key, required this.cle});
  final GlobalKey<ListePagineeState> cle;

  @override
  State<ListeTravaux> createState() => _ListeTravauxState();
}

class _ListeTravauxState extends State<ListeTravaux> {
  String _statut = 'ouverts';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Filtres(
        options: [('ouverts', 'En cours'), ('', 'Tous'), for (final o in refs.options('statut_travaux')) (o.code, o.label)],
        valeur: _statut,
        onChange: (v) => setState(() => _statut = v),
      ),
      Expanded(
        child: ListePaginee(
          key: widget.cle,
          cle: _statut,
          vide: 'Aucun chantier',
          iconeVide: Icons.handyman_outlined,
          charger: (page) async {
            final r = await api.get<Map<String, dynamic>>('/travaux', query: {
              'page': page,
              if (_statut != 'ouverts') 'status': _statut,
              'tri': '-created_at',
            });
            if (_statut != 'ouverts') return r;
            // « En cours » : tout ce qui n'est ni terminé ni annulé
            return {...r, 'items': (r['items'] as List).where((t) => !['termine', 'annule'].contains((t as Map)['status'])).toList()};
          },
          element: (context, t) => ListTile(
            title: Text('${t['reference']} · ${t['title']}'),
            subtitle: Text([
              (t['building'] as Map?)?['name'],
              if (t['apartment'] != null) 'Appart. ${(t['apartment'] as Map)['number']}',
              refs.libelle('priorite', t['priority'] as String?),
            ].whereType<String>().join(' · ')),
            trailing: Statut(FamilleStatut.travaux, 'statut_travaux', t['status'] as String?),
            onTap: () async {
              await ouvrir(context, TravauxDetail(id: '${t['id']}'));
              widget.cle.currentState?.recharger();
            },
          ),
        ),
      ),
    ]);
  }
}

class ListeArtisans extends StatelessWidget {
  const ListeArtisans({super.key, required this.cle});
  final GlobalKey<ListePagineeState> cle;

  @override
  Widget build(BuildContext context) {
    return ListePaginee(
      key: cle,
      vide: 'Aucun artisan',
      iconeVide: Icons.engineering_outlined,
      charger: (page) => api.get('/artisans', query: {'page': page, 'tri': 'name'}),
      element: (context, a) => ListTile(
        leading: CircleAvatar(child: Icon(a['is_active'] == true ? Icons.engineering_outlined : Icons.block, size: 20)),
        title: Text('${a['name']}'),
        subtitle: Text('${refs.libelle('metier_artisan', a['trade'] as String?)} · ${a['interventions_count'] ?? 0} intervention(s) · ${montant(a['total_spent'] as num?)}'),
        trailing: a['is_active'] == true ? const Icon(Icons.chevron_right) : const Pastille('Inactif'),
        onTap: () async {
          await ouvrir(context, ArtisanDetail(id: '${a['id']}'));
          cle.currentState?.recharger();
        },
      ),
    );
  }
}
