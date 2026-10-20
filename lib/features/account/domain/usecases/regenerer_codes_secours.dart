import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/account_repository.dart';

class RegenererCodesSecours {
  final AccountRepository repository;
  RegenererCodesSecours(this.repository);

  Future<Either<Failure, List<String>>> call(
          {required String motDePasse, required String code}) =>
      repository.regenererCodesSecours(motDePasse: motDePasse, code: code);
}
