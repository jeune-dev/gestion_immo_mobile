import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/espace_locataire_repository.dart';

class ConsentirWhatsapp {
  final EspaceLocataireRepository repository;
  ConsentirWhatsapp(this.repository);

  Future<Either<Failure, void>> call({required bool accorde}) =>
      repository.consentementWhatsapp(accorde: accorde);
}
