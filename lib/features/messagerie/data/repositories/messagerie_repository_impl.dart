import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/messagerie.dart';
import '../../domain/repositories/messagerie_repository.dart';
import '../datasources/messagerie_remote_datasource.dart';

class MessagerieRepositoryImpl implements MessagerieRepository {
  final MessagerieRemoteDataSource remoteDataSource;
  MessagerieRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PageResultat<FilDiscussion>>> fils({
    required int page,
    required bool espaceLocataire,
  }) => appelApi(
    () => remoteDataSource.fils(page: page, espaceLocataire: espaceLocataire),
  );

  @override
  Future<Either<Failure, String?>> filAvecLocataire(String locataireId) =>
      appelApi(() async {
        final p = await remoteDataSource.fils(
          page: 1,
          espaceLocataire: false,
          limite: 100,
        );
        for (final f in p.items) {
          if (f.locataire?.id == locataireId) return f.id;
        }
        return null;
      });

  @override
  Future<Either<Failure, List<Message>>> messages(
    String filId, {
    required bool espaceLocataire,
  }) => appelApi(
    () => remoteDataSource.messages(filId, espaceLocataire: espaceLocataire),
  );

  @override
  Future<Either<Failure, void>> marquerLu(
    String filId, {
    required bool espaceLocataire,
  }) => appelApi(
    () => remoteDataSource.marquerLu(filId, espaceLocataire: espaceLocataire),
  );

  @override
  Future<Either<Failure, Message>> envoyerTexte(
    String texte, {
    String? filId,
    String? locataireId,
  }) => appelApi(
    () => remoteDataSource.envoyerTexte(
      texte,
      filId: filId,
      locataireId: locataireId,
    ),
  );

  @override
  Future<Either<Failure, Message>> envoyerPhoto(
    String chemin, {
    String? filId,
    String? locataireId,
  }) => appelApi(
    () => remoteDataSource.envoyerPhoto(
      chemin,
      filId: filId,
      locataireId: locataireId,
    ),
  );
}
