import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/definir_activite_artisan.dart';
import '../../domain/usecases/get_artisan.dart';
import '../../domain/usecases/supprimer_artisan.dart';
import 'artisan_event.dart';
import 'artisan_state.dart';

class ArtisanBloc extends Bloc<ArtisanEvent, ArtisanState> {
  final GetArtisan getArtisan;
  final DefinirActiviteArtisan definirActiviteArtisan;
  final SupprimerArtisan supprimerArtisan;

  ArtisanBloc({
    required this.getArtisan,
    required this.definirActiviteArtisan,
    required this.supprimerArtisan,
  }) : super(ArtisanInitial()) {
    on<LoadArtisan>(_onLoadArtisan);
    on<RafraichirArtisan>(_onRafraichirArtisan);
    on<DefinirActiviteArtisanEvent>(_onDefinirActiviteArtisan);
    on<SupprimerArtisanEvent>(_onSupprimerArtisan);
    on<ResetArtisanState>((_, emit) => emit(ArtisanInitial()));
  }

  Future<void> _onLoadArtisan(
    LoadArtisan event,
    Emitter<ArtisanState> emit,
  ) async {
    emit(ArtisanLoading());
    await _relire(event.id, emit);
  }

  Future<void> _onRafraichirArtisan(
    RafraichirArtisan event,
    Emitter<ArtisanState> emit,
  ) async {
    await _relire(event.id, emit);
  }

  Future<void> _onDefinirActiviteArtisan(
    DefinirActiviteArtisanEvent event,
    Emitter<ArtisanState> emit,
  ) async {
    final result = await definirActiviteArtisan(event.id, actif: event.actif);
    await result.fold(
      (failure) async => emit(ArtisanActionError(failure)),
      (_) async {
        emit(ArtisanSuccess(
            message: event.actif ? 'Artisan réactivé' : 'Artisan désactivé'));
        await _relire(event.id, emit);
      },
    );
  }

  Future<void> _onSupprimerArtisan(
    SupprimerArtisanEvent event,
    Emitter<ArtisanState> emit,
  ) async {
    final result = await supprimerArtisan(event.id);
    result.fold(
      (failure) => emit(ArtisanActionError(failure)),
      (_) => emit(ArtisanSupprime()),
    );
  }

  /// Relit la fiche. Si elle est déjà affichée, un échec de relecture
  /// n'efface pas l'écran : il s'affiche comme un message.
  Future<void> _relire(String id, Emitter<ArtisanState> emit) async {
    final dejaAffichee = state is! ArtisanInitial &&
        state is! ArtisanLoading &&
        state is! ArtisanError;
    final result = await getArtisan(id);
    result.fold(
      (failure) => emit(
        dejaAffichee ? ArtisanActionError(failure) : ArtisanError(failure),
      ),
      (artisan) => emit(ArtisanLoaded(artisan)),
    );
  }
}
