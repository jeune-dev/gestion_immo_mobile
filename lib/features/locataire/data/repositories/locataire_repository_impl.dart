import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/exceptions.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
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
  }) async {
    try {
      final locataires = await remoteDataSource.getLocataires(
        page: page,
        recherche: recherche,
      );
      return Right(locataires);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  @override
  Future<Either<Failure, Locataire>> getLocataire(String id) async {
    try {
      final locataire = await remoteDataSource.getLocataire(id);
      return Right(locataire);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  @override
  Future<Either<Failure, LocataireCree>> creerLocataire(
    Map<String, dynamic> data, {
    required String cle,
  }) async {
    try {
      final (locataire, invitation) =
          await remoteDataSource.creerLocataire(data, cle: cle);
      return Right(LocataireCree(locataire: locataire, invitation: invitation));
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  @override
  Future<Either<Failure, Locataire>> modifierLocataire(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final locataire = await remoteDataSource.modifierLocataire(id, data);
      return Right(locataire);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerLocataire(String id) async {
    try {
      await remoteDataSource.supprimerLocataire(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  @override
  Future<Either<Failure, Invitation>> inviterLocataire(String id) async {
    try {
      final invitation = await remoteDataSource.inviterLocataire(id);
      return Right(invitation);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  @override
  Future<Either<Failure, void>> enregistrerConsentementWhatsapp(
    String id, {
    required bool accorde,
  }) async {
    try {
      await remoteDataSource.enregistrerConsentementWhatsapp(
        id,
        accorde: accorde,
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure.depuis(e));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _messageInattendu(e)));
    }
  }

  String _messageInattendu(Object e) => 'Réponse inattendue du serveur ($e)';
}
