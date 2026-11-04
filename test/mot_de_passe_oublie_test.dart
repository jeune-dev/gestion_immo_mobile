import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/demander_reinitialisation.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/reinitialiser_mot_de_passe.dart';
import 'package:gestion_immo_mobile/features/auth/domain/usecases/verifier_code_reinitialisation.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/mot_de_passe_oublie_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/mot_de_passe_oublie_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/mot_de_passe_oublie_state.dart';

/// Dépôt simulé : seules les trois étapes du mot de passe oublié sont utilisées.
class _Depot implements AuthRepository {
  final appels = <String>[];
  Failure? echecReinitialisation;

  @override
  Future<Either<Failure, void>> demanderReinitialisation(
      String identifiant) async {
    appels.add('demande:$identifiant');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> verifierCodeReinitialisation(
      String identifiant, String code) async {
    appels.add('verification:$identifiant:$code');
    return code == 'K7P2QX9M'
        ? const Right(null)
        : Left(ServerFailure(errorMessage: 'Code incorrect', code: 'CODE_INVALIDE'));
  }

  @override
  Future<Either<Failure, void>> reinitialiserMotDePasse(
      Map<String, dynamic> corps) async {
    appels.add('reinitialisation:${corps['identifiant']}:${corps['code']}');
    final echec = echecReinitialisation;
    return echec == null ? const Right(null) : Left(echec);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MotDePasseOublieBloc _bloc(_Depot depot) => MotDePasseOublieBloc(
      demanderReinitialisation: DemanderReinitialisation(depot),
      verifierCode: VerifierCodeReinitialisation(depot),
      reinitialiserMotDePasse: ReinitialiserMotDePasse(depot),
    );

Future<MotDePasseOublieState> _apres(
    MotDePasseOublieBloc bloc, MotDePasseOublieEvent e) async {
  bloc.add(e);
  return bloc.stream.firstWhere((s) => s is! MotDePasseOublieLoading);
}

void main() {
  test('code de réinitialisation : 8 lettres ou chiffres, casse et espaces indifférents', () {
    expect(IdentifiantValidator.codeReinitialisation('k7p2 qx9m').valeur, 'K7P2QX9M');
    expect(IdentifiantValidator.codeReinitialisation('K7P2QX9').erreurFormulaire, isNotNull);
    expect(IdentifiantValidator.codeReinitialisation('K7P2-X9M').erreurFormulaire, isNotNull);
  });

  test('parcours en trois étapes : demande → code vérifié → nouveau mot de passe', () async {
    final depot = _Depot();
    final bloc = _bloc(depot);
    expect(await _apres(bloc, EnvoyerCodeEvent(' awa@demo.sn ')), isA<CodeEnvoye>());
    expect(bloc.state.etape, EtapeReinitialisation.code);

    final faux = await _apres(bloc, VerifierCodeEvent('AAAAAAAA'));
    expect(faux, isA<MotDePasseOublieError>());
    expect(faux.etape, EtapeReinitialisation.code);

    expect(await _apres(bloc, VerifierCodeEvent('K7P2QX9M')), isA<CodeVerifie>());
    expect(bloc.state.etape, EtapeReinitialisation.motDePasse);

    expect(
        await _apres(bloc,
            ReinitialiserMotDePasseEvent(motDePasse: 'Nouveau9', confirmation: 'Nouveau9')),
        isA<MotDePasseReinitialise>());
    expect(depot.appels, [
      'demande:awa@demo.sn',
      'verification:awa@demo.sn:AAAAAAAA',
      'verification:awa@demo.sn:K7P2QX9M',
      'reinitialisation:awa@demo.sn:K7P2QX9M',
    ]);
    await bloc.close();
  });

  test('code expiré entre la vérification et la réinitialisation : retour à l’étape du code', () async {
    final depot = _Depot()
      ..echecReinitialisation = ServerFailure(errorMessage: 'Trop d’essais', code: 'CODE_EPUISE');
    final bloc = _bloc(depot);
    await _apres(bloc, EnvoyerCodeEvent('awa@demo.sn'));
    await _apres(bloc, VerifierCodeEvent('K7P2QX9M'));
    final etat = await _apres(bloc,
        ReinitialiserMotDePasseEvent(motDePasse: 'Nouveau9', confirmation: 'Nouveau9'));
    expect(etat, isA<MotDePasseOublieError>());
    expect(etat.etape, EtapeReinitialisation.code);

    // « Renvoyer le code » repart avec le même identifiant.
    expect(await _apres(bloc, RenvoyerCodeEvent()), isA<CodeEnvoye>());
    expect(depot.appels.last, 'demande:awa@demo.sn');
    await bloc.close();
  });
}
