import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/ajouter_element_edl.dart';
import '../../domain/usecases/ajouter_photo_edl.dart';
import '../../domain/usecases/ajouter_piece_edl.dart';
import '../../domain/usecases/corriger_etat_des_lieux.dart';
import '../../domain/usecases/enregistrer_saisie_edl.dart';
import '../../domain/usecases/get_etat_des_lieux.dart';
import '../../domain/usecases/preciser_element_edl.dart';
import '../../domain/usecases/renommer_piece_edl.dart';
import '../../domain/usecases/soumettre_etat_des_lieux.dart';
import '../../domain/usecases/supprimer_element_edl.dart';
import '../../domain/usecases/supprimer_etat_des_lieux.dart';
import '../../domain/usecases/supprimer_photo_edl.dart';
import '../../domain/usecases/supprimer_piece_edl.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'etat_des_lieux_event.dart';
import 'etat_des_lieux_state.dart';

/// Fiche d'un état des lieux (§ 52) ; la saisie des états reste locale à
/// l'écran jusqu'à [enregistrerSaisie].
class EtatDesLieuxBloc extends Bloc<EtatDesLieuxEvent, EtatDesLieuxState> {
  final GetEtatDesLieux getEtatDesLieux;
  final AjouterPieceEdl ajouterPieceEdl;
  final RenommerPieceEdl renommerPieceEdl;
  final SupprimerPieceEdl supprimerPieceEdl;
  final AjouterElementEdl ajouterElementEdl;
  final PreciserElementEdl preciserElementEdl;
  final SupprimerElementEdl supprimerElementEdl;
  final AjouterPhotoEdl ajouterPhotoEdl;
  final SupprimerPhotoEdl supprimerPhotoEdl;
  final SoumettreEtatDesLieux soumettreEtatDesLieux;
  final SupprimerEtatDesLieux supprimerEtatDesLieux;
  final CorrigerEtatDesLieux corrigerEtatDesLieux;
  final EnregistrerSaisieEdl enregistrerSaisieEdl;

  EtatDesLieuxBloc({
    required this.getEtatDesLieux,
    required this.ajouterPieceEdl,
    required this.renommerPieceEdl,
    required this.supprimerPieceEdl,
    required this.ajouterElementEdl,
    required this.preciserElementEdl,
    required this.supprimerElementEdl,
    required this.ajouterPhotoEdl,
    required this.supprimerPhotoEdl,
    required this.soumettreEtatDesLieux,
    required this.supprimerEtatDesLieux,
    required this.corrigerEtatDesLieux,
    required this.enregistrerSaisieEdl,
  }) : super(EtatDesLieuxInitial()) {
    on<LoadEtatDesLieux>(_onLoadEtatDesLieux);
    on<RafraichirEtatDesLieux>(_onRafraichirEtatDesLieux);
    on<AjouterPieceEvent>(_onAjouterPiece);
    on<RenommerPieceEvent>(_onRenommerPiece);
    on<SupprimerPieceEvent>(_onSupprimerPiece);
    on<AjouterElementEvent>(_onAjouterElement);
    on<PreciserElementEvent>(_onPreciserElement);
    on<SupprimerElementEvent>(_onSupprimerElement);
    on<AjouterPhotoEvent>(_onAjouterPhoto);
    on<SupprimerPhotoEvent>(_onSupprimerPhoto);
    on<SoumettreEtatDesLieuxEvent>(_onSoumettreEtatDesLieux);
    on<SupprimerEtatDesLieuxEvent>(_onSupprimerEtatDesLieux);
    on<CorrigerEtatDesLieuxEvent>(_onCorrigerEtatDesLieux);
    on<ResetEtatDesLieuxState>((_, emit) => emit(EtatDesLieuxInitial()));
  }

  Future<void> _onLoadEtatDesLieux(
    LoadEtatDesLieux event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    emit(EtatDesLieuxLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirEtatDesLieux(
    RafraichirEtatDesLieux event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onAjouterPiece(
    AjouterPieceEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await ajouterPieceEdl(event.id, event.nom);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Pièce ajoutée'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onRenommerPiece(
    RenommerPieceEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await renommerPieceEdl(event.id, event.pieceId, event.nom);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Pièce renommée'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerPiece(
    SupprimerPieceEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await supprimerPieceEdl(event.id, event.pieceId);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Pièce supprimée'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onAjouterElement(
    AjouterElementEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await ajouterElementEdl(event.id, event.pieceId, event.data);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Élément ajouté'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onPreciserElement(
    PreciserElementEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result =
        await preciserElementEdl(event.id, event.elementId, event.precision);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Élément modifié'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerElement(
    SupprimerElementEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await supprimerElementEdl(event.id, event.elementId);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Élément supprimé'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onAjouterPhoto(
    AjouterPhotoEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result =
        await ajouterPhotoEdl(event.id, event.elementId, event.chemin);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Photo ajoutée'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerPhoto(
    SupprimerPhotoEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await supprimerPhotoEdl(event.id, event.photoId);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'Photo retirée'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSoumettreEtatDesLieux(
    SoumettreEtatDesLieuxEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await soumettreEtatDesLieux(event.id);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (_) async {
        emit(EtatDesLieuxSuccess(message: 'État des lieux soumis'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerEtatDesLieux(
    SupprimerEtatDesLieuxEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await supprimerEtatDesLieux(event.id);
    result.fold(
      (failure) => emit(EtatDesLieuxActionError(failure)),
      (_) => emit(EtatDesLieuxSupprime()),
    );
  }

  Future<void> _onCorrigerEtatDesLieux(
    CorrigerEtatDesLieuxEvent event,
    Emitter<EtatDesLieuxState> emit,
  ) async {
    final result = await corrigerEtatDesLieux(event.id);
    await result.fold(
      (failure) async => emit(EtatDesLieuxActionError(failure)),
      (version) async {
        emit(NouvelleVersionLoaded(version));
        emit(EtatDesLieuxSuccess(message: 'Nouvelle version créée'));
        await _relire(event.id, emit);
      },
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<EtatDesLieuxState> emit) async {
    final dejaAffichee = state is! EtatDesLieuxInitial &&
        state is! EtatDesLieuxLoading &&
        state is! EtatDesLieuxError;
    final result = await getEtatDesLieux(id);
    result.fold(
      (failure) => emit(
        dejaAffichee
            ? EtatDesLieuxActionError(failure)
            : EtatDesLieuxError(failure),
      ),
      (etatDesLieux) => emit(EtatDesLieuxLoaded(etatDesLieux)),
    );
  }

  /// Enregistre toutes les saisies en une requête (§ 52.4, saisie
  /// synchronisée) ; renvoie l'échec éventuel pour que l'écran garde ses
  /// saisies.
  Future<Failure?> enregistrerSaisie(
    String id,
    List<Map<String, dynamic>> elements,
  ) async {
    final result = await enregistrerSaisieEdl(id, elements);
    return result.fold((failure) => failure, (_) {
      add(RafraichirEtatDesLieux(id));
      return null;
    });
  }
}
