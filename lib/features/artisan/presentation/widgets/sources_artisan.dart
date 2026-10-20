import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/entities/artisan.dart';
import 'package:gestion_immo_mobile/features/artisan/domain/usecases/get_artisans.dart';

/// Sélection d'un artisan actif.
SourceEntite<Artisan> sourceArtisans() => SourceEntite<Artisan>(
      charger: (page, q) => sl<GetArtisans>()(
          page: page, recherche: q.isEmpty ? null : q, actifsSeulement: true),
      id: (e) => e.id,
      libelle: (e) => e.nom,
      sousTitre: (e) => e.telephone ?? '',
    );
