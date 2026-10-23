import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/entities/espace_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/repositories/espace_locataire_repository.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/get_moyens_paiement_locataire.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/payer_en_ligne.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_bloc.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_event.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/bloc/paiement_locataire_state.dart';

class _Depot implements EspaceLocataireRepository {
  int nbPaiements = 0;
  final reponse = Completer<Either<Failure, DemandePaiement>>();

  @override
  Future<Either<Failure, MoyensPaiementLocataire>> moyensPaiement(
    String bailId,
  ) async => const Right(MoyensPaiementLocataire(integres: ['wave']));

  @override
  Future<Either<Failure, DemandePaiement>> payer({
    String? echeanceId,
    String? chargeId,
    required String portefeuille,
    int? montant,
  }) {
    nbPaiements++;
    return reponse.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('un double toucher sur « Payer » ne crée qu’une demande', () async {
    final depot = _Depot();
    final bloc = PaiementLocataireBloc(
      getMoyensPaiementLocataire: GetMoyensPaiementLocataire(depot),
      payerEnLigne: PayerEnLigne(depot),
    );
    bloc.add(LoadPaiementLocataire('bail'));
    await bloc.stream.firstWhere((s) => s is PaiementLocataireLoaded);

    bloc
      ..add(PayerEnLigneEvent('bail', 'ech', 5000, 'wave'))
      ..add(PayerEnLigneEvent('bail', 'ech', 5000, 'wave'));
    await bloc.stream.firstWhere(
      (s) => s is PaiementLocataireLoaded && s.paiementEnCours,
    );
    await pumpEventQueue();
    expect(depot.nbPaiements, 1);

    depot.reponse.complete(const Right(DemandePaiement(transactionId: 't1')));
    await bloc.stream.firstWhere((s) => s is DemandePaiementLoaded);
    bloc.add(PayerEnLigneEvent('bail', 'ech', 5000, 'wave'));
    await pumpEventQueue();
    expect(depot.nbPaiements, 1);
    await bloc.close();
  });
}
