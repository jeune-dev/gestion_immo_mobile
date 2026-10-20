import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/annuler_facture_commune.dart';
import '../../domain/usecases/get_facture_commune.dart';
import '../../domain/usecases/joindre_document_facture.dart';
import 'facture_commune_event.dart';
import 'facture_commune_state.dart';

class FactureCommuneBloc
    extends Bloc<FactureCommuneEvent, FactureCommuneState> {
  final GetFactureCommune getFactureCommune;
  final JoindreDocumentFacture joindreDocumentFacture;
  final AnnulerFactureCommune annulerFactureCommune;

  FactureCommuneBloc({
    required this.getFactureCommune,
    required this.joindreDocumentFacture,
    required this.annulerFactureCommune,
  }) : super(FactureCommuneInitial()) {
    on<LoadFactureCommune>(_onLoadFactureCommune);
    on<RafraichirFactureCommune>(_onRafraichirFactureCommune);
    on<JoindreDocumentFactureEvent>(_onJoindreDocumentFacture);
    on<AnnulerFactureCommuneEvent>(_onAnnulerFactureCommune);
    on<ResetFactureCommuneState>((_, emit) => emit(FactureCommuneInitial()));
  }

  Future<void> _onLoadFactureCommune(
    LoadFactureCommune event,
    Emitter<FactureCommuneState> emit,
  ) async {
    emit(FactureCommuneLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirFactureCommune(
    RafraichirFactureCommune event,
    Emitter<FactureCommuneState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onJoindreDocumentFacture(
    JoindreDocumentFactureEvent event,
    Emitter<FactureCommuneState> emit,
  ) async {
    final result = await joindreDocumentFacture(event.id, event.chemin);
    await result.fold(
      (failure) async => emit(FactureCommuneActionError(failure)),
      (_) async {
        emit(FactureCommuneSuccess(message: 'Facture jointe'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onAnnulerFactureCommune(
    AnnulerFactureCommuneEvent event,
    Emitter<FactureCommuneState> emit,
  ) async {
    final result = await annulerFactureCommune(event.id, event.motif);
    await result.fold(
      (failure) async => emit(FactureCommuneActionError(failure)),
      (_) async {
        emit(FactureCommuneSuccess(message: 'Facture annulée'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<FactureCommuneState> emit) async {
    final dejaAffichee = state is! FactureCommuneInitial &&
        state is! FactureCommuneLoading &&
        state is! FactureCommuneError;
    final result = await getFactureCommune(id);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? FactureCommuneActionError(failure)
            : FactureCommuneError(failure),
      ),
      (facture) => emit(FactureCommuneLoaded(facture)),
    );
  }
}
