import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/tableau_de_bord.dart';
import '../repositories/dashboard_repository.dart';

class GetTableauDeBord {
  final DashboardRepository repository;
  GetTableauDeBord(this.repository);

  Future<Either<Failure, TableauDeBord>> call() => repository.tableauDeBord();
}
