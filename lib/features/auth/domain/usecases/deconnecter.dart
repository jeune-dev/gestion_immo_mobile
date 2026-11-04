import '../repositories/auth_repository.dart';

class Deconnecter {
  final AuthRepository repository;
  Deconnecter(this.repository);

  Future<void> call({bool sessionExpiree = false}) =>
      repository.deconnecter(sessionExpiree: sessionExpiree);
}
