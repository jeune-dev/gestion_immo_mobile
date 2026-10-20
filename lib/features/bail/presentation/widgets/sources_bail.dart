import 'package:gestion_immo_mobile/core/models/personne_resume.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/bail/domain/entities/bail.dart';
import 'package:gestion_immo_mobile/features/bail/domain/usecases/get_baux.dart';

/// Sélection d'un bail (vide = tous les statuts).
SourceEntite<Bail> sourceBaux({String statut = 'actif'}) => SourceEntite<Bail>(
      charger: (page, _) =>
          sl<GetBaux>()(page: page, statut: statut.isEmpty ? null : statut),
      recherche: false,
      id: (e) => e.id,
      libelle: (e) => '${nomDe(e.locataire)} · ${e.logement?.numero ?? ''}',
      sousTitre: (e) => '${e.reference ?? ''} · ${montant(e.loyer)}',
    );
