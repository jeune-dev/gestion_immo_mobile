import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/utils/choisir_photo.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/section_documents.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/bloc/facture_commune_bloc.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/bloc/facture_commune_event.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/bloc/facture_commune_state.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/widgets/formulaire_facture.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/repartition_page.dart';

class FactureCommuneDetailPage extends StatelessWidget {
  final String id;
  const FactureCommuneDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<FactureCommuneBloc>()..add(LoadFactureCommune(id)),
      child: BlocConsumer<FactureCommuneBloc, FactureCommuneState>(
        listener: (context, state) {
          if (state is FactureCommuneSuccess) {
            afficherSucces(context, state.message);
          } else if (state is FactureCommuneActionError) {
            afficherErreurApi(context, state.failure);
          }
        },
        // Les états d'action (message…) ne redessinent pas l'écran.
        buildWhen: (_, state) =>
            state is FactureCommuneInitial ||
            state is FactureCommuneLoading ||
            state is FactureCommuneLoaded ||
            state is FactureCommuneError,
        builder: (context, state) {
          if (state is FactureCommuneLoaded) {
            return _buildFiche(context, state.facture);
          }
          return VueChargement(
            titre: 'Facture commune',
            failure: state is FactureCommuneError ? state.failure : null,
            onReessayer: () =>
                context.read<FactureCommuneBloc>().add(LoadFactureCommune(id)),
          );
        },
      ),
    );
  }

  Widget _buildFiche(BuildContext context, FactureCommune f) {
    final bloc = context.read<FactureCommuneBloc>();
    return Scaffold(
      appBar: AppBar(
        title: Text(refs.libelle('type_charge', f.typeCharge)),
        actions: [
          if (f.statut != 'annulee')
            MenuActions(
              actions: [
                if (f.brouillon)
                  (
                    'Modifier',
                    () async {
                      if (await modifierFactureCommune(context, f) != null) {
                        bloc.add(RafraichirFactureCommune(id));
                      }
                    },
                    false,
                  ),
                (
                  'Joindre la facture',
                  () async {
                    final photo = await choisirPhoto(context);
                    if (photo != null) {
                      bloc.add(JoindreDocumentFactureEvent(id, photo.path));
                    }
                  },
                  false,
                ),
                (
                  'Annuler la facture',
                  () async {
                    final motif = await confirmer(
                      context,
                      titre: 'Annuler la facture',
                      message:
                          'Les charges refacturées non payées seront annulées.',
                      motif: true,
                      danger: true,
                    );
                    if (motif != null) {
                      bloc.add(AnnulerFactureCommuneEvent(id, motif));
                    }
                  },
                  true,
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: f.brouillon
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await ouvrir<bool>(context, RepartitionPage(facture: f)) ==
                    true) {
                  bloc.add(RafraichirFactureCommune(id));
                }
              },
              icon: const Icon(Icons.call_split),
              label: const Text('Répartir'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Section(
            children: [
              Ligne('Immeuble', f.immeubleNom ?? ''),
              Ligne('Fournisseur', f.fournisseur),
              Ligne('N° de facture', f.numeroFacture),
              Ligne(
                  'Période', '${date(f.debutPeriode)} → ${date(f.finPeriode)}'),
              Ligne('Montant', montant(f.montant)),
              Ligne('Échéance', date(f.dateLimite)),
              Ligne('Méthode',
                  refs.libelle('methode_repartition', f.methodeRepartition)),
              Ligne('Refacturée aux locataires', f.refacturer ? 'Oui' : 'Non'),
              Ligne('Statut', refs.libelle('statut_facture_commune', f.statut)),
            ],
          ),
          if (f.repartition.isNotEmpty) ...[
            const SizedBox(height: 16),
            Section(
              titre: 'Répartition',
              padding: false,
              children: [
                for (final l in f.repartition)
                  ListTile(
                    title: Text('Appartement ${l.logementNumero ?? ''}'),
                    subtitle: Text(l.explication ?? ''),
                    trailing: Montant(l.montant),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SectionDocuments(
              type: 'charge_invoice',
              ajout: false,
              id: id,
              titre: 'Pièces jointes'),
        ],
      ),
    );
  }
}
