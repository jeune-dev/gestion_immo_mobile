import '../repositories/auth_repository.dart';

enum SessionRestauree {
  /// Aucune session sur l'appareil.
  aucune,

  /// Session renouvelée auprès du serveur.
  renouvelee,

  /// Pas de réseau : le jeton reste valable, le compte se lit depuis le cache.
  horsLigne,

  /// Refus explicite du serveur : la session est terminée.
  refusee,
}

/// Au lancement : session restaurée depuis le refresh token du coffre.
class RestaurerSession {
  final AuthRepository repository;
  RestaurerSession(this.repository);

  Future<SessionRestauree> call() async {
    if (!await repository.sessionEnregistree()) return SessionRestauree.aucune;
    if (await repository.restaurerSession()) return SessionRestauree.renouvelee;
    // Le client efface le jeton sur un refus (401) ; il le garde sur une erreur réseau.
    return await repository.sessionEnregistree()
        ? SessionRestauree.horsLigne
        : SessionRestauree.refusee;
  }
}
