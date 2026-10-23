import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_moyens_paiement_locataire.dart';
import '../../domain/usecases/payer_en_ligne.dart';
import 'paiement_locataire_event.dart';
import 'paiement_locataire_state.dart';

/// Paiement d'une échéance (§ 12, § 51) : moyens ouverts par le bailleur.
class PaiementLocataireBloc
    extends Bloc<PaiementLocataireEvent, PaiementLocataireState> {
  final GetMoyensPaiementLocataire getMoyensPaiementLocataire;
  final PayerEnLigne payerEnLigne;
  bool _paiementEnCours = false;

  PaiementLocataireBloc({
    required this.getMoyensPaiementLocataire,
    required this.payerEnLigne,
  }) : super(PaiementLocataireInitial()) {
    on<LoadPaiementLocataire>(_onLoadPaiementLocataire);
    on<RafraichirPaiementLocataire>(_onRafraichirPaiementLocataire);
    on<PayerEnLigneEvent>(_onPayerEnLigne);
    on<ResetPaiementLocataireState>(
        (_, emit) => emit(PaiementLocataireInitial()));
  }

  Future<void> _onLoadPaiementLocataire(
    LoadPaiementLocataire event,
    Emitter<PaiementLocataireState> emit,
  ) async {
    emit(PaiementLocataireLoading());
    await _relire(event.bailId, emit);
  }

  Future<void> _onRafraichirPaiementLocataire(
    RafraichirPaiementLocataire event,
    Emitter<PaiementLocataireState> emit,
  ) async {
    await _relire(event.bailId, emit);
  }

  /// Une seule demande à la fois : un double toucher créerait deux paiements
  /// PayDunya (chaque envoi porte sa propre `Idempotency-Key`).
  Future<void> _onPayerEnLigne(
    PayerEnLigneEvent event,
    Emitter<PaiementLocataireState> emit,
  ) async {
    final fiche = state;
    if (_paiementEnCours || fiche is! PaiementLocataireLoaded) return;
    _paiementEnCours = true;
    emit(PaiementLocataireLoaded(fiche.moyens, paiementEnCours: true));
    final result = await payerEnLigne(
      echeanceId: event.echeanceId,
      portefeuille: event.portefeuille,
      montant: event.montant,
    );
    result.fold(
      (failure) {
        _paiementEnCours = false;
        emit(PaiementLocataireActionError(failure));
        emit(PaiementLocataireLoaded(fiche.moyens));
      },
      // Succès : l'écran est remplacé par le suivi, les boutons restent bloqués
      (demande) => emit(DemandePaiementLoaded(demande)),
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(
      String bailId, Emitter<PaiementLocataireState> emit) async {
    final dejaAffichee = state is! PaiementLocataireInitial &&
        state is! PaiementLocataireLoading &&
        state is! PaiementLocataireError;
    final result = await getMoyensPaiementLocataire(bailId);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? PaiementLocataireActionError(failure)
            : PaiementLocataireError(failure),
      ),
      (moyens) => emit(PaiementLocataireLoaded(moyens,
          paiementEnCours: _paiementEnCours)),
    );
  }
}
