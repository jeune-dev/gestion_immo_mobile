import 'package:dartz/dartz.dart';

import 'failure.dart';

/// Valeur d'un `Either`, ou lève la [Failure] (formulaires génériques, `Future` attendus).
extension EitherOuLeve<T> on Either<Failure, T> {
  T ouLeve() => fold((f) => throw f, (v) => v);
}

/// Lance deux lectures en parallèle ; échoue dès que l'une échoue.
Future<Either<Failure, (A, B)>> ensemble<A, B>(
    Future<Either<Failure, A>> a, Future<Either<Failure, B>> b) async {
  final (ra, rb) = await (a, b).wait;
  return ra.fold(
      (f) => Left(f), (va) => rb.fold((f) => Left(f), (vb) => Right((va, vb))));
}

/// Variante à trois lectures.
Future<Either<Failure, (A, B, C)>> ensemble3<A, B, C>(
  Future<Either<Failure, A>> a,
  Future<Either<Failure, B>> b,
  Future<Either<Failure, C>> c,
) async {
  final (ra, rb, rc) = await (a, b, c).wait;
  return ra.fold(
      (f) => Left(f),
      (va) => rb.fold((f) => Left(f),
          (vb) => rc.fold((f) => Left(f), (vc) => Right((va, vb, vc)))));
}
