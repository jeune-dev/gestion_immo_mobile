import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_tableau_de_bord.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetTableauDeBord getTableauDeBord;

  DashboardBloc({
    required this.getTableauDeBord,
  }) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RafraichirDashboard>(_onRafraichirDashboard);
    on<ResetDashboardState>((_, emit) => emit(DashboardInitial()));
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _relire(emit);
  }

  Future<void> _onRafraichirDashboard(
    RafraichirDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    await _relire(emit);
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(Emitter<DashboardState> emit) async {
    final dejaAffichee = state is! DashboardInitial &&
        state is! DashboardLoading &&
        state is! DashboardError;
    final result = await getTableauDeBord();
    result.fold(
      (failure) => emit(
        dejaAffichee ? DashboardActionError(failure) : DashboardError(failure),
      ),
      (tableauDeBord) => emit(DashboardLoaded(tableauDeBord)),
    );
  }
}
