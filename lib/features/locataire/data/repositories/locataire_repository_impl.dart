import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/locataire.dart';
import '../../domain/repositories/locataire_repository.dart';
import '../datasources/locataire_remote_datasource.dart';

class LocataireRepositoryImpl implements LocataireRepository {
  final LocataireRemoteDataSource remoteDataSource;
  LocataireRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<Locataire>>> getLocataires({
    required int page,
    String? recherche,
  }) => appelApi(
    () => remoteDataSource.getLocataires(page: page, recherche: recherche),
  );

  @override
  Future<Either<Failure, Locataire>> getLocataire(String id) =>
      appelApi(() => remoteDataSource.getLocataire(id));

  @override
  Future<Either<Failure, LocataireCree>> creerLocataire(
    Map<String, dynamic> data, {
    required String cle,
  }) => appelApi(() async {
    final (locataire, invitation) = await remoteDataSource.creerLocataire(
      data,
      cle: cle,
    );
    return LocataireCree(locataire: locataire, invitation: invitation);
  });

  @override
  Future<Either<Failure, Locataire>> modifierLocataire(
    String id,
    Map<String, dynamic> data,
  ) => appelApi(() => remoteDataSource.modifierLocataire(id, data));

  @override
  Future<Either<Failure, void>> supprimerLocataire(String id) =>
      appelApi(() => remoteDataSource.supprimerLocataire(id));

  @override
  Future<Either<Failure, Invitation>> inviterLocataire(String id) =>
      appelApi(() => remoteDataSource.inviterLocataire(id));

  @override
  Future<Either<Failure, void>> enregistrerConsentementWhatsapp(
    String id, {
    required bool accorde,
  }) => appelApi(
    () =>
        remoteDataSource.enregistrerConsentementWhatsapp(id, accorde: accorde),
  );
}
