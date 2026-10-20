import '../repositories/auth_repository.dart';

class Deconnecter {
  final AuthRepository repository;
  Deconnecter(this.repository);

  Future<void> call() => repository.deconnecter();
}
