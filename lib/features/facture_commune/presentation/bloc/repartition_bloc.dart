import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestion_immo_mobile/features/appartement/domain/usecases/get_appartements.dart';
import '../../domain/usecases/previsualiser_repartition.dart';
import '../../domain/usecases/repartir_facture.dart';
import 'repartition_event.dart';
import 'repartition_state.dart';

/// Répartition (§ 17) : appartements de l'immeuble, aperçu calculé par l'API,
/// validation.
class RepartitionBloc extends Bloc<RepartitionEvent, RepartitionState> {
  final GetAppartements getAppartements;
  final PrevisualiserRepartition previsualiserRepartition;
  final RepartirFacture repartirFacture;

  RepartitionBloc({
    required this.getAppartements,
    required this.previsualiserRepartition,
    required this.repartirFacture,
  }) : super(RepartitionInitial()) {
    on<LoadRepartition>(_onLoadRepartition);
    on<InvaliderApercuEvent>(_onInvaliderApercu);
    on<PrevisualiserRepartitionEvent>(_onPrevisualiserRepartition);
    on<RepartirFactureEvent>(_onRepartirFacture);
  }

  Future<void> _onLoadRepartition(
    LoadRepartition event,
    Emitter<RepartitionState> emit,
  ) async {
    final result = await getAppartements(
      page: 1,
      immeubleId: event.facture.immeubleId,
      limite: 100,
    );
    result.fold(
      (failure) => emit(RepartitionError(failure)),
      (page) => emit(RepartitionLoaded(appartements: page.items)),
    );
  }

  void _onInvaliderApercu(
    InvaliderApercuEvent event,
    Emitter<RepartitionState> emit,
  ) {
    final actuel = state;
    if (actuel is RepartitionLoaded) {
      emit(actuel.copyWith(effacerApercu: true));
    }
  }

  Future<void> _onPrevisualiserRepartition(
    PrevisualiserRepartitionEvent event,
    Emitter<RepartitionState> emit,
  ) async {
    final actuel = state;
    if (actuel is! RepartitionLoaded) return;
    emit(actuel.copyWith(enCours: true));
    final result = await previsualiserRepartition(event.factureId, event.data);
    result.fold(
      (failure) {
        emit(RepartitionActionError(failure));
        emit(actuel.copyWith(enCours: false));
      },
      (apercu) => emit(actuel.copyWith(apercu: apercu)),
    );
  }

  Future<void> _onRepartirFacture(
    RepartirFactureEvent event,
    Emitter<RepartitionState> emit,
  ) async {
    final actuel = state;
    if (actuel is! RepartitionLoaded) return;
    emit(actuel.copyWith(enCours: true));
    final result = await repartirFacture(event.factureId, event.data);
    result.fold(
      (failure) {
        emit(RepartitionActionError(failure));
        emit(actuel.copyWith(enCours: false));
      },
      (_) => emit(RepartitionSuccess()),
    );
  }
}
