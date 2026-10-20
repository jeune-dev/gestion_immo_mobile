import 'package:dartz/dartz.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import '../entities/tableau_de_bord.dart';

abstract class DashboardRepository {
  Future<Either<Failure, TableauDeBord>> tableauDeBord();
}
