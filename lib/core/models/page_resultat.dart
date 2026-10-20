import 'package:equatable/equatable.dart';

/// Page d'une liste de l'API : `{ items, pagination: { page, totalPages, total } }` (contrat § 0).
class PageResultat<T> extends Equatable {
  final List<T> items;
  final int page;
  final int totalPages;
  final int total;

  bool get aSuite => page < totalPages;

  const PageResultat(
      {required this.items,
      required this.page,
      required this.totalPages,
      required this.total});

  factory PageResultat.depuisJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) convertir) {
    final p = (json['pagination'] as Map?) ?? const {};
    final items = ((json['items'] as List?) ?? const [])
        .map((e) => convertir(Map<String, dynamic>.from(e as Map)))
        .toList();
    final page = (p['page'] as num?)?.toInt() ?? 1;
    return PageResultat(
      items: items,
      page: page,
      totalPages: (p['totalPages'] as num?)?.toInt() ?? page,
      total: (p['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  List<Object?> get props => [items, page, totalPages, total];
}

extension FiltrePage<T> on PageResultat<T> {
  /// Même page, sans les éléments écartés (filtre local en complément de l'API).
  PageResultat<T> filtrer(bool Function(T) garder) => PageResultat<T>(
      items: items.where(garder).toList(),
      page: page,
      totalPages: totalPages,
      total: total);
}
