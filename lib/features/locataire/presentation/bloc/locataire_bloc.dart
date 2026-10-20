import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/enregistrer_consentement_whatsapp.dart';
import '../../domain/usecases/get_locataire.dart';
import '../../domain/usecases/inviter_locataire.dart';
import '../../domain/usecases/supprimer_locataire.dart';
import 'locataire_event.dart';
import 'locataire_state.dart';

/// Bloc de la fiche d'un locataire.
///
/// Après une action réussie, la fiche est relue sans repasser par
/// [LocataireLoading] : l'écran garde son contenu et affiche le message.
class LocataireBloc extends Bloc<LocataireEvent, LocataireState> {
  final GetLocataire getLocataire;
  final SupprimerLocataire supprimerLocataire;
  final InviterLocataire inviterLocataire;
  final EnregistrerConsentementWhatsapp enregistrerConsentementWhatsapp;

  LocataireBloc({
    required this.getLocataire,
    required this.supprimerLocataire,
    required this.inviterLocataire,
    required this.enregistrerConsentementWhatsapp,
  }) : super(LocataireInitial()) {
    on<LoadLocataire>(_onLoadLocataire);
    on<RafraichirLocataire>(_onRafraichirLocataire);
    on<SupprimerLocataireEvent>(_onSupprimerLocataire);
    on<InviterLocataireEvent>(_onInviterLocataire);
    on<EnregistrerConsentementWhatsappEvent>(_onEnregistrerConsentement);
    on<ResetLocataireState>((_, emit) => emit(LocataireInitial()));
  }

  Future<void> _onLoadLocataire(
    LoadLocataire event,
    Emitter<LocataireState> emit,
  ) async {
    emit(LocataireLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirLocataire(
    RafraichirLocataire event,
    Emitter<LocataireState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onSupprimerLocataire(
    SupprimerLocataireEvent event,
    Emitter<LocataireState> emit,
  ) async {
    final result = await supprimerLocataire(event.id);
    result.fold(
      (failure) => emit(LocataireActionError(failure)),
      (_) => emit(LocataireSupprime()),
    );
  }

  Future<void> _onInviterLocataire(
    InviterLocataireEvent event,
    Emitter<LocataireState> emit,
  ) async {
    final result = await inviterLocataire(event.id);
    await result.fold(
      (failure) async => emit(LocataireActionError(failure)),
      (invitation) async {
        emit(LocataireInvitationLoaded(invitation));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onEnregistrerConsentement(
    EnregistrerConsentementWhatsappEvent event,
    Emitter<LocataireState> emit,
  ) async {
    final result = await enregistrerConsentementWhatsapp(
      event.id,
      accorde: true,
    );
    await result.fold(
      (failure) async => emit(LocataireActionError(failure)),
      (_) async {
        emit(LocataireSuccess(message: 'Consentement enregistré'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si une fiche est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<LocataireState> emit) async {
    final dejaAffichee = state is! LocataireInitial &&
        state is! LocataireLoading &&
        state is! LocataireError;
    final result = await getLocataire(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? LocataireActionError(failure) : LocataireError(failure),
      ),
      (locataire) => emit(LocataireLoaded(locataire)),
    );
  }
}
