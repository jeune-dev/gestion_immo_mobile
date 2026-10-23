import 'package:dartz/dartz.dart' show Either;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';

/// Charge une page `n` (1, 2…) d'une liste de l'API via un cas d'usage.
typedef ChargeurPage<T> = Future<Either<Failure, PageResultat<T>>> Function(
    int page);

class PaginationState<T> extends Equatable {
  final List<T> items;
  final int page;
  final int totalPages;
  final bool enCours;
  final Failure? failure;

  bool get aSuite => page < totalPages;

  const PaginationState(
      {this.items = const [],
      this.page = 0,
      this.totalPages = 1,
      this.enCours = false,
      this.failure});

  PaginationState<T> copyWith(
          {List<T>? items,
          int? page,
          int? totalPages,
          bool? enCours,
          Failure? failure,
          bool effacerErreur = false}) =>
      PaginationState<T>(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        enCours: enCours ?? this.enCours,
        failure: effacerErreur ? null : failure ?? this.failure,
      );

  @override
  List<Object?> get props => [items, page, totalPages, enCours, failure];
}

/// Liste à chargement progressif (cahier des charges § 37) : première page,
/// pages suivantes au défilement, rechargement complet.
class PaginationCubit<T> extends Cubit<PaginationState<T>> {
  ChargeurPage<T> _charger;

  /// Incrémenté à chaque rechargement : la réponse d'un chargement plus ancien
  /// (autre filtre, page suivante en vol) est ignorée au lieu d'être mélangée.
  int _generation = 0;
  PaginationCubit(this._charger) : super(PaginationState<T>());

  /// Nouveau chargeur (filtre changé) puis rechargement depuis la première page.
  Future<void> changerSource(ChargeurPage<T> charger) {
    _charger = charger;
    return recharger();
  }

  Future<void> recharger() async {
    if (isClosed) return;
    _generation++;
    emit(PaginationState<T>(enCours: true));
    await _charge(1, remplacer: true);
  }

  Future<void> suivante() async {
    if (isClosed || state.enCours || !state.aSuite) return;
    emit(state.copyWith(enCours: true, effacerErreur: true));
    await _charge(state.page + 1);
  }

  Future<void> _charge(int page, {bool remplacer = false}) async {
    final generation = _generation;
    final r = await _charger(page);
    if (isClosed || generation != _generation) return;
    r.fold(
      (f) => emit(state.copyWith(enCours: false, failure: f)),
      (p) => emit(PaginationState<T>(
          items: remplacer ? p.items : [...state.items, ...p.items],
          page: p.page,
          totalPages: p.totalPages)),
    );
  }
}
