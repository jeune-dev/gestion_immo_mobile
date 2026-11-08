import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/echeance/data/models/echeance_detail_model.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/entities/echeance_detail.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/repositories/echeance_repository.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/annuler_echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/domain/usecases/get_echeance.dart';
import 'package:gestion_immo_mobile/features/echeance/presentation/pages/echeance_detail_page.dart';
import 'package:gestion_immo_mobile/features/facture_commune/data/models/facture_commune_model.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/entities/facture_commune.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/repositories/facture_commune_repository.dart';
import 'package:gestion_immo_mobile/features/facture_commune/domain/usecases/get_charge_refacturee.dart';
import 'package:gestion_immo_mobile/features/facture_commune/presentation/pages/charge_detail_page.dart';
import 'package:gestion_immo_mobile/features/quittance/data/models/quittance_model.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/entities/quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/repositories/quittance_repository.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/usecases/get_quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/domain/usecases/telecharger_quittance.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittance_detail_page.dart';

// Réponses réelles des routes de détail de l'API (champs utiles seulement).

const _logement = {
  'id': 'apt1',
  'number': 'A12',
  'building': {'id': 'imm1', 'name': 'Résidence Les Almadies'},
};

Map<String, dynamic> _echeance({
  String status = 'paye',
  bool locataire = false,
}) => {
  'id': 'ech1',
  'lease_id': 'bail1',
  'period_start': '2026-09-01',
  'period_end': '2026-09-30',
  'due_date': '2026-09-05',
  'label': 'Loyer septembre 2026',
  'rent_amount': 320000,
  'charges_amount': 30000,
  'amount_due': 350000,
  'amount_paid': status == 'paye' ? 350000 : 100000,
  'status': status,
  'paid_at': status == 'paye' ? '2026-09-05T10:00:00.000Z' : null,
  if (!locataire) ...{
    'tenant': {
      'id': 'loc1',
      'first_name': 'Mamadou',
      'last_name': 'Ndiaye',
      'phone': '+221770000000',
    },
    'apartment': _logement,
  },
  'allocations': [
    {
      'id': 'al1',
      'amount': 100000,
      'created_at': '2026-09-03T09:00:00.000Z',
      'payment': {
        'id': 'p1',
        'reference': 'PAY-20260903-001',
        'method': 'especes',
        'paid_on': '2026-09-03',
      },
    },
    if (status == 'paye')
      {
        'id': 'al2',
        'amount': 250000,
        'created_at': '2026-09-05T09:00:00.000Z',
        'payment': {
          'id': 'p2',
          'reference': 'PAY-20260905-001',
          'method': 'especes',
          'paid_on': '2026-09-05',
        },
      },
  ],
  'receipt': status == 'paye'
      ? {
          'id': 'qui1',
          'number': 'QUI-2026-00001',
          'issued_at': '2026-09-05T10:00:01.000Z',
        }
      : null,
};

final _quittance = {
  'id': 'qui1',
  'number': 'QUI-2026-00001',
  'amount': 350000,
  'issued_at': '2026-09-05T10:00:01.000Z',
  'payment_references': ['PAY-20260903-001', 'PAY-20260905-001'],
  'cancelled_at': null,
  'tenant': {'id': 'loc1', 'first_name': 'Mamadou', 'last_name': 'Ndiaye'},
  'schedule': {
    'id': 'ech1',
    'label': 'Loyer septembre 2026',
    'period_start': '2026-09-01',
    'period_end': '2026-09-30',
    'due_date': '2026-09-05',
    'amount_due': 350000,
    'apartment': _logement,
  },
};

final _charge = {
  'id': 'ch1',
  'charge_type': 'eau',
  'label': 'Eau septembre 2026 — SEN’EAU',
  'amount': 30000,
  'amount_paid': 0,
  'due_date': '2026-11-23',
  'status': 'a_payer',
  'tenant': {'id': 'loc1', 'first_name': 'Mamadou', 'last_name': 'Ndiaye'},
  'apartment': _logement,
  'invoice': {
    'id': 'fac1',
    'supplier': 'SEN’EAU',
    'invoice_number': 'T-001',
    'period_start': '2026-09-01',
    'period_end': '2026-09-30',
    'allocation_method': 'egale',
    'amount': 90000,
    'status': 'repartie',
  },
  'remaining': 30000,
  'allocation': {
    'basis_value': 1,
    'share': 0.3333,
    'amount': 30000,
    'provision_deducted': 5000,
    'explanation': '90 000 FCFA ÷ 3 appartements = 30 000 FCFA',
  },
};

class _Echeances implements EcheanceRepository {
  final EcheanceDetail fiche;
  bool? espaceLocataire;
  _Echeances(this.fiche);

  @override
  Future<Either<Failure, EcheanceDetail>> getEcheance(
    String id, {
    bool espaceLocataire = false,
  }) async {
    this.espaceLocataire = espaceLocataire;
    return Right(fiche);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quittances implements QuittanceRepository {
  @override
  Future<Either<Failure, Quittance>> getQuittance(
    String id, {
    required bool espaceLocataire,
  }) async => Right(QuittanceModel.fromJson(_quittance));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Charges implements FactureCommuneRepository {
  @override
  Future<Either<Failure, ChargeRefacturee>> charge(String id) async =>
      Right(ChargeRefactureeModel.fromJson(_charge));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Référentiels non chargés : les codes s'affichent tels quels.
class _Refs extends ChangeNotifier implements ReferentielsService {
  @override
  String libelle(String famille, String? code) => code ?? '—';

  @override
  List<OptionRef> options(String famille) => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _afficher(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.clair, home: page));
  await tester.pumpAndSettle();
}

void main() {
  final sl = GetIt.instance;
  setUp(() => sl.registerSingleton<ReferentielsService>(_Refs()));
  tearDown(sl.reset);

  group('lecture des réponses de détail', () {
    test('échéance propriétaire : décomposition, paiements, quittance', () {
      final d = EcheanceDetailModel.fromJson(_echeance());
      expect(d.echeance.id, 'ech1');
      expect(d.echeance.bailId, 'bail1');
      expect(d.echeance.reste, 0);
      expect(d.echeance.logementNumero, 'A12');
      expect(d.echeance.locataire?.prenom, 'Mamadou');
      expect(d.immeuble, 'Résidence Les Almadies');
      expect((d.loyer, d.charges), (320000, 30000));
      expect((d.periodeDebut, d.periodeFin), ('2026-09-01', '2026-09-30'));
      // Les paiements les plus récents d'abord.
      expect(d.imputations.map((i) => i.reference), [
        'PAY-20260905-001',
        'PAY-20260903-001',
      ]);
      expect(d.imputations.first.moyen, 'especes');
      expect(d.imputations.first.payeLe, '2026-09-05');
      expect(d.quittance?.id, 'qui1');
      expect(d.quittance?.numero, 'QUI-2026-00001');
    });

    test(
      'échéance locataire : ni fiche locataire ni logement, sans quittance',
      () {
        final d = EcheanceDetailModel.fromJson(
          _echeance(status: 'partiellement_paye', locataire: true),
        );
        expect(d.echeance.locataire, isNull);
        expect(d.immeuble, isNull);
        expect(d.echeance.reste, 250000);
        expect(d.echeance.payable, isTrue);
        expect(d.imputations, hasLength(1));
        expect(d.quittance, isNull);
      },
    );

    test('quittance : période, logement et références de paiement', () {
      final q = QuittanceModel.fromJson(_quittance);
      expect(q.libelleEcheance, 'Loyer septembre 2026');
      expect((q.periodeDebut, q.periodeFin), ('2026-09-01', '2026-09-30'));
      expect((q.logementNumero, q.immeuble), ('A12', 'Résidence Les Almadies'));
      expect(q.referencesPaiement, ['PAY-20260903-001', 'PAY-20260905-001']);
      expect(q.annulee, isFalse);
    });

    test('charge propriétaire : facture et ligne de répartition', () {
      final c = ChargeRefactureeModel.fromJson(_charge);
      final k = c.calcul!;
      expect(c.reste, 30000);
      expect(k.fournisseur, 'SEN’EAU');
      expect(k.numeroFacture, 'T-001');
      expect(k.methode, 'egale');
      expect(k.totalFacture, 90000);
      expect(k.provisionDeduite, 5000);
      expect(k.explication, startsWith('90 000 FCFA'));
    });
  });

  group('fiches', () {
    testWidgets('échéance propriétaire soldée : paiements et quittance', (
      tester,
    ) async {
      final depot = _Echeances(EcheanceDetailModel.fromJson(_echeance()));
      sl
        ..registerSingleton(GetEcheance(depot))
        ..registerSingleton(AnnulerEcheance(depot));
      await _afficher(tester, const EcheanceDetailPage(id: 'ech1'));

      expect(depot.espaceLocataire, isFalse);
      expect(find.text('Mamadou Ndiaye'), findsOneWidget);
      expect(find.textContaining('PAY-20260905-001'), findsOneWidget);
      expect(find.textContaining('PAY-20260903-001'), findsOneWidget);
      expect(find.text('N° QUI-2026-00001'), findsOneWidget);
      // Soldée : ni encaissement ni annulation.
      expect(find.text('Encaisser'), findsNothing);
      expect(find.text("Annuler l'échéance"), findsNothing);
    });

    testWidgets('échéance propriétaire en cours : encaisser seulement', (
      tester,
    ) async {
      final depot = _Echeances(
        EcheanceDetailModel.fromJson(_echeance(status: 'partiellement_paye')),
      );
      sl
        ..registerSingleton(GetEcheance(depot))
        ..registerSingleton(AnnulerEcheance(depot));
      await _afficher(tester, const EcheanceDetailPage(id: 'ech1'));

      expect(find.text('Encaisser'), findsOneWidget);
      // Déjà partiellement payée : l'annulation n'est pas proposée.
      expect(find.text("Annuler l'échéance"), findsNothing);
    });

    testWidgets('échéance locataire : bouton Payer, sans nom du locataire', (
      tester,
    ) async {
      final depot = _Echeances(
        EcheanceDetailModel.fromJson(
          _echeance(status: 'partiellement_paye', locataire: true),
        ),
      );
      sl
        ..registerSingleton(GetEcheance(depot))
        ..registerSingleton(AnnulerEcheance(depot));
      await _afficher(
        tester,
        const EcheanceDetailPage(id: 'ech1', espaceLocataire: true),
      );

      expect(depot.espaceLocataire, isTrue);
      expect(find.textContaining('Payer'), findsOneWidget);
      expect(find.text('Encaisser'), findsNothing);
      expect(find.text('Locataire'), findsNothing);
    });

    testWidgets('quittance : détail, références et actions PDF', (
      tester,
    ) async {
      final depot = _Quittances();
      sl
        ..registerSingleton(GetQuittance(depot))
        ..registerSingleton(TelechargerQuittance(depot));
      await _afficher(tester, const QuittanceDetailPage(id: 'qui1'));

      expect(find.text('N° QUI-2026-00001'), findsOneWidget);
      expect(
        find.text('Résidence Les Almadies · Appartement A12'),
        findsOneWidget,
      );
      expect(find.text('PAY-20260903-001, PAY-20260905-001'), findsOneWidget);
      expect(find.text('Voir le PDF'), findsOneWidget);
      expect(find.text('Partager'), findsOneWidget);
    });

    testWidgets('charge refacturée : facture et répartition', (tester) async {
      sl.registerSingleton(GetChargeRefacturee(_Charges()));
      await _afficher(tester, const ChargeDetailPage(id: 'ch1'));

      expect(find.text('Mamadou Ndiaye'), findsOneWidget);
      expect(find.text('SEN’EAU'), findsOneWidget);
      expect(find.text('T-001'), findsOneWidget);
      expect(find.text('Provision déduite'), findsOneWidget);
      expect(find.textContaining('÷ 3 appartements'), findsOneWidget);
    });
  });
}
