import 'package:dartz/dartz.dart';
import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../repositories/locataire_repository.dart';

class EnregistrerConsentementWhatsapp {
  final LocataireRepository repository;
  EnregistrerConsentementWhatsapp(this.repository);

  Future<Either<Failure, void>> call(String id, {required bool accorde}) =>
      repository.enregistrerConsentementWhatsapp(id, accorde: accorde);
}
