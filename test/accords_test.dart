import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_immo_mobile/features/bail/data/models/bail_model.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/data/models/accords_model.dart';
import 'package:gestion_immo_mobile/features/paiement/data/models/paiement_model.dart';

void main() {
  test('bail : accord du locataire, congé et avenant en attente', () {
    final b = BailModel.fromJson({
      'id': 'b1',
      'status': 'actif',
      'proposed_at': '2026-11-01T10:00:00Z',
      'tenant_accepted_at': '2026-11-02T10:00:00Z',
      'acceptance_method': 'papier',
      'notice_given_by': 'locataire',
      'planned_exit_date': '2027-02-28',
      'amendments': [
        {
          'id': 'a2',
          'status': 'refuse',
          'previous_rent_amount': 150000,
          'previous_charges_amount': 10000,
          'rent_amount': 170000,
          'charges_amount': 10000,
          'effective_from': '2026-12-01',
          'refusal_reason': 'Trop cher',
        },
        {
          'id': 'a1',
          'status': 'propose',
          'previous_rent_amount': '150000',
          'previous_charges_amount': '10000',
          'rent_amount': '160000',
          'charges_amount': '15000',
          'effective_from': '2027-01-01',
        },
      ],
    });
    expect(b.modeAccord, 'papier');
    expect(b.congePar, 'locataire');
    expect(b.sortiePrevue, '2027-02-28');
    expect(b.avenants, hasLength(2));
    final enAttente = b.avenantEnAttente!;
    expect(enAttente.id, 'a1');
    expect(enAttente.totalAvant, 160000);
    expect(enAttente.total, 175000);
  });

  test('espace locataire : bail proposé et nouveau loyer à accepter', () {
    final a = accordsDepuis({
      'leases': [
        {
          'id': 'l1',
          'reference': 'BAIL-2026-0001',
          'start_date': '2026-12-01',
          'rent_amount': 200000,
          'charges_amount': 15000,
          'deposit_amount': 400000,
          'notice_period_months': 2,
          'contract_document_id': 'd1',
          'apartment': {
            'number': 'A3',
            'building': {'id': 'i1', 'name': 'Résidence Fann', 'city': 'Dakar'},
          },
          'owner': {'display_name': 'Balla Diop'},
        },
      ],
      'amendments': [
        {
          'id': 'av1',
          'status': 'propose',
          'previous_rent_amount': 100000,
          'previous_charges_amount': 0,
          'rent_amount': 110000,
          'charges_amount': 0,
          'effective_from': '2027-01-01',
          'lease': {
            'reference': 'BAIL-2025-0004',
            'apartment': {
              'number': 'B1',
              'building': {'name': 'Les Almadies'},
            },
          },
        },
      ],
    });
    expect(a.nombre, 2);
    final b = a.baux.single;
    expect(b.logement, 'Résidence Fann · appartement A3');
    expect(b.bailleur, 'Balla Diop');
    expect(b.preavisMois, 2);
    expect(b.contratDocumentId, 'd1');
    expect(a.avenants.single.logement, 'Les Almadies · appartement B1');
    expect(a.avenants.single.avenant.total, 110000);
  });

  test('paiement remboursé et contesté', () {
    final p = PaiementModel.fromJson({
      'id': 'p1',
      'status': 'rembourse',
      'dispute_status': 'resolu',
      'dispute_message': 'Rien reçu',
      'dispute_response': 'Remis le 3',
    });
    expect(p.contestation, 'resolu');
    expect(p.messageContestation, 'Rien reçu');
    expect(p.reponseContestation, 'Remis le 3');
  });
}
