import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/entities/locataire.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/usecases/get_locataires.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;

/// Sélection d'un locataire dans un formulaire.
SourceEntite<Locataire> sourceLocataires() => SourceEntite<Locataire>(
      charger: (page, query) => di.sl<GetLocataires>()(
        page: page,
        recherche: query.isEmpty ? null : query,
      ),
      id: (locataire) => locataire.id,
      libelle: (locataire) => locataire.nomComplet,
      sousTitre: (locataire) => locataire.telephone ?? '',
    );
