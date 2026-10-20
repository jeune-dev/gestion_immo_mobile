import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/models/page_resultat.dart';
import '../entities/messagerie.dart';
import '../repositories/messagerie_repository.dart';

class GetFilsDiscussion {
  final MessagerieRepository repository;
  GetFilsDiscussion(this.repository);

  Future<Either<Failure, PageResultat<FilDiscussion>>> call(
          {required int page, bool espaceLocataire = false}) =>
      repository.fils(page: page, espaceLocataire: espaceLocataire);
}
