import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/get_echeances.dart';

/// Échéances non soldées d'un bail, des plus anciennes aux plus récentes.
SourceEntite<Echeance> sourceEcheancesImpayees(String bailId) =>
    SourceEntite<Echeance>(
      charger: (page, _) =>
          sl<GetEcheances>()(page: page, bailId: bailId, impayes: true),
      recherche: false,
      id: (e) => e.id,
      libelle: (e) => e.libelle ?? '',
      sousTitre: (e) =>
          'Reste ${montant(e.reste)} · échéance ${date(e.dateEcheance)}',
    );
