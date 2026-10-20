import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/entities/immeuble.dart';
import 'package:gestion_immo_mobile/features/immeuble/domain/usecases/get_immeubles.dart';

/// Sélection d'un immeuble dans un formulaire.
SourceEntite<Immeuble> sourceImmeubles() => SourceEntite<Immeuble>(
      charger: (page, q) =>
          sl<GetImmeubles>()(page: page, recherche: q.isEmpty ? null : q),
      id: (e) => e.id,
      libelle: (e) => e.nom,
      sousTitre: (e) => [e.adresse, e.ville].whereType<String>().join(', '),
    );
