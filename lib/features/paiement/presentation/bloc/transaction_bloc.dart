import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_transaction.dart';
import '../../domain/usecases/rejeter_transaction.dart';
import '../../domain/usecases/valider_transaction.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransaction getTransaction;
  final ValiderTransaction validerTransaction;
  final RejeterTransaction rejeterTransaction;

  TransactionBloc({
    required this.getTransaction,
    required this.validerTransaction,
    required this.rejeterTransaction,
  }) : super(TransactionInitial()) {
    on<LoadTransaction>(_onLoadTransaction);
    on<RafraichirTransaction>(_onRafraichirTransaction);
    on<ValiderTransactionEvent>(_onValiderTransaction);
    on<RejeterTransactionEvent>(_onRejeterTransaction);
    on<ResetTransactionState>((_, emit) => emit(TransactionInitial()));
  }

  Future<void> _onLoadTransaction(
    LoadTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirTransaction(
    RafraichirTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onValiderTransaction(
    ValiderTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await validerTransaction(event.id);
    await result.fold(
      (failure) async => emit(TransactionActionError(failure)),
      (_) async {
        emit(TransactionSuccess(message: 'Paiement validé'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onRejeterTransaction(
    RejeterTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await rejeterTransaction(event.id, event.motif);
    await result.fold(
      (failure) async => emit(TransactionActionError(failure)),
      (_) async {
        emit(TransactionSuccess(message: 'Preuve rejetée'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<TransactionState> emit) async {
    final dejaAffichee = state is! TransactionInitial &&
        state is! TransactionLoading &&
        state is! TransactionError;
    final result = await getTransaction(id);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? TransactionActionError(failure)
            : TransactionError(failure),
      ),
      (transaction) => emit(TransactionLoaded(transaction)),
    );
  }
}
