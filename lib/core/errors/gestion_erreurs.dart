import 'package:dartz/dartz.dart';

import 'exceptions.dart';
import 'failure.dart';

/// Appel de l'API par un dépôt : la valeur, ou l'échec normalisé.
///
/// Une [ApiException] (erreur HTTP, réseau) devient la [Failure] qui porte son
/// `error.code` ; toute autre erreur (réponse illisible, champ manquant) devient
/// une [ServerFailure] « Réponse inattendue du serveur ».
Future<Either<Failure, T>> appelApi<T>(Future<T> Function() appel) async {
  try {
    return Right(await appel());
  } on ApiException catch (e) {
    return Left(Failure.depuis(e));
  } catch (e) {
    return Left(
      ServerFailure(errorMessage: 'Réponse inattendue du serveur ($e)'),
    );
  }
}

/// Valeur d'un `Either`, ou lève la [Failure] (formulaires génériques, `Future` attendus).
extension EitherOuLeve<T> on Either<Failure, T> {
  T ouLeve() => fold((f) => throw f, (v) => v);
}

/// Lance deux lectures en parallèle ; échoue dès que l'une échoue.
Future<Either<Failure, (A, B)>> ensemble<A, B>(
  Future<Either<Failure, A>> a,
  Future<Either<Failure, B>> b,
) async {
  final (ra, rb) = await (a, b).wait;
  return ra.fold(
    (f) => Left(f),
    (va) => rb.fold((f) => Left(f), (vb) => Right((va, vb))),
  );
}
