import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/paiement.dart';

abstract class PaiementRepository {
  Future<Either<Failure, int>> encaisser(Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, PageResultat<Paiement>>> getPaiements(
      {required int page, String? moyen});
  Future<Either<Failure, FichePaiement>> getFichePaiement(String id);
  Future<Either<Failure, void>> rembourser(
      String id, Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, PageResultat<TransactionPaiement>>> transactions(
      {required int page, String? statut, bool preuvesSeulement = false});
  Future<Either<Failure, TransactionPaiement>> transaction(String id);
  Future<Either<Failure, void>> validerTransaction(String id);
  Future<Either<Failure, void>> rejeterTransaction(String id, String motif);
  Future<Either<Failure, PageResultat<Rapprochement>>> rapprochements(
      {required int page, String? statut});
  Future<Either<Failure, void>> resoudreRapprochement(
      String id, Map<String, dynamic> corps,
      {required String cle});
  Future<Either<Failure, void>> rejeterRapprochement(
      String id, Map<String, dynamic> corps);
  Future<Either<Failure, List<MoyenPaiement>>> moyens();
  Future<Either<Failure, void>> configurerMoyen(Map<String, dynamic> corps);
}
