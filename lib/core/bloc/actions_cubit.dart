import 'package:dartz/dartz.dart' show Either;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';

class EtatActions extends Equatable {
  final bool enCours;
  final Failure? failure;
  final String? succes;

  /// Valeur renvoyée par la dernière action réussie.
  final Object? resultat;
  final int version;

  bool get reussi => failure == null && version > 0;

  const EtatActions(
      {this.enCours = false,
      this.failure,
      this.succes,
      this.resultat,
      this.version = 0});

  @override
  List<Object?> get props => [enCours, failure, succes, resultat, version];
}

/// Actions ponctuelles d'un écran de liste (annuler, valider, rejeter…) :
/// exécute le cas d'usage et publie le résultat ; l'écran recharge sa liste.
class ActionsCubit extends Cubit<EtatActions> {
  ActionsCubit() : super(const EtatActions());

  Future<bool> executer<R>(Future<Either<Failure, R>> action,
      {String? succes}) async {
    emit(EtatActions(enCours: true, version: state.version));
    final r = await action;
    emit(
      r.fold(
          (f) => EtatActions(failure: f, version: state.version + 1),
          (v) => EtatActions(
              succes: succes, resultat: v, version: state.version + 1)),
    );
    return r.isRight();
  }
}
