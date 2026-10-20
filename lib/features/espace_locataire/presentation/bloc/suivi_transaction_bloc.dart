import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_ma_transaction.dart';
import 'suivi_transaction_event.dart';
import 'suivi_transaction_state.dart';

/// Suivi d'un paiement en ligne : la confirmation vient du serveur (webhook
/// PayDunya). Vérification toutes les 5 s pendant 5 minutes, puis à la
/// demande.
class SuiviTransactionBloc
    extends Bloc<SuiviTransactionEvent, SuiviTransactionState> {
  final GetMaTransaction getMaTransaction;

  Timer? _minuterie;
  int _essais = 0;

  SuiviTransactionBloc({required this.getMaTransaction})
      : super(SuiviTransactionInitial()) {
    on<DemarrerSuiviTransaction>(_onDemarrerSuivi);
    on<VerifierTransactionEvent>(_onVerifierTransaction);
  }

  Future<void> _onDemarrerSuivi(
    DemarrerSuiviTransaction event,
    Emitter<SuiviTransactionState> emit,
  ) async {
    _minuterie?.cancel();
    _minuterie = Timer.periodic(const Duration(seconds: 5), (_) {
      final termine = state is SuiviTransactionLoaded &&
          (state as SuiviTransactionLoaded).transaction.termine;
      if (++_essais > 60 || termine) {
        _minuterie?.cancel();
      } else {
        add(VerifierTransactionEvent(event.id));
      }
    });
    await _verifier(event.id, emit);
  }

  Future<void> _onVerifierTransaction(
    VerifierTransactionEvent event,
    Emitter<SuiviTransactionState> emit,
  ) async {
    await _verifier(event.id, emit);
  }

  Future<void> _verifier(
    String id,
    Emitter<SuiviTransactionState> emit,
  ) async {
    final result = await getMaTransaction(id);
    // Erreur : nouvelle tentative au prochain passage
    result.fold(
      (_) {},
      (transaction) => emit(SuiviTransactionLoaded(transaction)),
    );
  }

  @override
  Future<void> close() {
    _minuterie?.cancel();
    return super.close();
  }
}
