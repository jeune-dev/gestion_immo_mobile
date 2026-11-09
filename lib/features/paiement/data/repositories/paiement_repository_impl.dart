import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/gestion_erreurs.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

import '../../domain/entities/paiement.dart';
import '../../domain/repositories/paiement_repository.dart';
import '../datasources/paiement_remote_datasource.dart';

class PaiementRepositoryImpl implements PaiementRepository {
  final PaiementRemoteDataSource remoteDataSource;
  PaiementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, int>> encaisser(
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.encaisser(corps, cle: cle));

  @override
  Future<Either<Failure, PageResultat<Paiement>>> getPaiements({
    required int page,
    String? moyen,
  }) => appelApi(() => remoteDataSource.getPaiements(page: page, moyen: moyen));

  @override
  Future<Either<Failure, FichePaiement>> getFichePaiement(String id) =>
      appelApi(() async {
        final (paiement, quittances) = await (
          remoteDataSource.getPaiement(id),
          remoteDataSource.quittances(id),
        ).wait;
        return FichePaiement(paiement: paiement, quittances: quittances);
      });

  @override
  Future<Either<Failure, void>> rembourser(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(() => remoteDataSource.rembourser(id, corps, cle: cle));

  @override
  Future<Either<Failure, Uint8List>> recu(String id) =>
      appelApi(() => remoteDataSource.recu(id));

  @override
  Future<Either<Failure, void>> repondreContestation(
    String id,
    String reponse,
  ) => appelApi(() => remoteDataSource.repondreContestation(id, reponse));

  @override
  Future<Either<Failure, PageResultat<TransactionPaiement>>> transactions({
    required int page,
    String? statut,
    bool preuvesSeulement = false,
  }) => appelApi(
    () => remoteDataSource.transactions(
      page: page,
      statut: statut,
      preuvesSeulement: preuvesSeulement,
    ),
  );

  @override
  Future<Either<Failure, TransactionPaiement>> transaction(String id) =>
      appelApi(() => remoteDataSource.transaction(id));

  @override
  Future<Either<Failure, void>> validerTransaction(String id) =>
      appelApi(() => remoteDataSource.validerTransaction(id));

  @override
  Future<Either<Failure, void>> rejeterTransaction(String id, String motif) =>
      appelApi(() => remoteDataSource.rejeterTransaction(id, motif));

  @override
  Future<Either<Failure, PageResultat<Rapprochement>>> rapprochements({
    required int page,
    String? statut,
  }) => appelApi(
    () => remoteDataSource.rapprochements(page: page, statut: statut),
  );

  @override
  Future<Either<Failure, void>> resoudreRapprochement(
    String id,
    Map<String, dynamic> corps, {
    required String cle,
  }) => appelApi(
    () => remoteDataSource.resoudreRapprochement(id, corps, cle: cle),
  );

  @override
  Future<Either<Failure, void>> rejeterRapprochement(
    String id,
    Map<String, dynamic> corps,
  ) => appelApi(() => remoteDataSource.rejeterRapprochement(id, corps));

  @override
  Future<Either<Failure, List<MoyenPaiement>>> moyens() =>
      appelApi(() => remoteDataSource.moyens());

  @override
  Future<Either<Failure, void>> configurerMoyen(Map<String, dynamic> corps) =>
      appelApi(() => remoteDataSource.configurerMoyen(corps));
}
