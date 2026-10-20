import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/entities/appartement.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/usecases/get_appartements.dart';

/// Sélection d'un appartement, éventuellement d'un immeuble ou d'un statut donnés.
SourceEntite<Appartement> sourceAppartements(
        {String? immeuble, String? statut}) =>
    SourceEntite<Appartement>(
      charger: (page, q) => sl<GetAppartements>()(
          page: page,
          recherche: q.isEmpty ? null : q,
          statut: statut,
          immeubleId: immeuble),
      id: (e) => e.id,
      libelle: (e) => 'Appartement ${e.numero}',
      sousTitre: (e) => '${e.immeubleNom ?? ''} · ${montant(e.loyer)}',
    );
