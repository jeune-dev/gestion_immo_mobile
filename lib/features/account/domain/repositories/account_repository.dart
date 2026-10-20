import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/session_appareil.dart';

abstract class AccountRepository {
  Future<Either<Failure, void>> modifierProfil(Map<String, dynamic> corps);
  Future<Either<Failure, List<SessionAppareil>>> sessions();
  Future<Either<Failure, void>> revoquerSession(String id);
  Future<Either<Failure, void>> revoquerAutres();
  Future<Either<Failure, SecretMfa>> initialiserMfa(String motDePasse);

  /// Active la double authentification ; renvoie les codes de secours (à n'afficher qu'une fois).
  Future<Either<Failure, List<String>>> activerMfa(String code);
  Future<Either<Failure, void>> desactiverMfa(
      {required String motDePasse, required String code});
  Future<Either<Failure, List<String>>> regenererCodesSecours(
      {required String motDePasse, required String code});
}
