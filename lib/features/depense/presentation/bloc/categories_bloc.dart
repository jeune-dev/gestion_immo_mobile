import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/desactiver_categorie_depense.dart';
import '../../domain/usecases/get_categories_depenses.dart';
import 'categories_event.dart';
import 'categories_state.dart';

/// Catégories de dépenses, y compris les inactives.
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final GetCategoriesDepenses getCategoriesDepenses;
  final DesactiverCategorieDepense desactiverCategorieDepense;

  CategoriesBloc({
    required this.getCategoriesDepenses,
    required this.desactiverCategorieDepense,
  }) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<RafraichirCategories>(_onRafraichirCategories);
    on<DesactiverCategorieEvent>(_onDesactiverCategorie);
    on<ResetCategoriesState>((_, emit) => emit(CategoriesInitial()));
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirCategories(
    RafraichirCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    await _relire(emit);
  }

  Future<void> _onDesactiverCategorie(
    DesactiverCategorieEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await desactiverCategorieDepense(event.categorieId);
    await result.fold(
      (failure) async => emit(CategoriesActionError(failure)),
      (_) async {
        emit(CategoriesSuccess(message: 'Catégorie désactivée'));
        await _relire(emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<CategoriesState> emit) async {
    final dejaAffichee = state is! CategoriesInitial &&
        state is! CategoriesLoading &&
        state is! CategoriesError;
    final result = await getCategoriesDepenses(inclureInactives: true);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? CategoriesActionError(failure)
            : CategoriesError(failure),
      ),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }
}
