import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/formulaire.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../commun/documents.dart';

/// Paiement d'une échéance par le locataire (§ 12, § 51). Jamais hors ligne :
/// toute confirmation vient du serveur. Renvoie `true` si un paiement a été initié.
Future<bool?> payer(BuildContext context, {required Map echeance, required String bailId}) {
  return Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PaiementScreen(echeance: echeance, bailId: bailId)));
}

class PaiementScreen extends StatelessWidget {
  const PaiementScreen({super.key, required this.echeance, required this.bailId});
  final Map echeance;
  final String bailId;

  int get _reste => entier(echeance['amount_due']) - entier(echeance['amount_paid']);

  /// Paiement intégré : demande de paiement PayDunya, puis page Wave / Orange Money.
  Future<void> _integre(BuildContext context, String portefeuille) async {
    final cle = nouvelleCle();
    final r = await executer(
      context,
      () => api.post<Map<String, dynamic>>('/locataire/paiements',
          body: {'rent_schedule_id': echeance['id'], 'wallet': portefeuille, 'amount': _reste}, idempotence: cle),
    );
    if (r == null || !context.mounted) return;
    final url = r['checkout_url'] as String?;
    if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuiviTransactionScreen(id: '${(r['transaction'] as Map)['id']}', checkoutUrl: url),
    ));
  }

  /// Paiement direct : le locataire a payé sur le numéro du propriétaire et déclare la transaction.
  Future<void> _preuve(BuildContext context, Map moyen) async {
    String? photo;
    final cle = nouvelleCle();
    final r = await EcranFormulaire.ouvrir<Map>(
      context,
      EcranFormulaire(
        titre: 'Déclarer mon paiement ${refs.libelle('portefeuille', moyen['wallet'] as String?)}',
        initial: {'amount': _reste},
        intro: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Encadre('Envoyez ${montant(_reste)} au ${moyen['account_number']} (${moyen['label'] ?? refs.libelle('portefeuille', moyen['wallet'] as String?)}), '
              'puis indiquez ci-dessous le numéro de transaction reçu par SMS. Votre propriétaire validera le paiement.'),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (ctx, setState) => OutlinedButton.icon(
              onPressed: () async {
                final p = await choisirPhoto(ctx);
                if (p != null) setState(() => photo = p.path);
              },
              icon: Icon(photo == null ? Icons.add_a_photo_outlined : Icons.check),
              label: Text(photo == null ? 'Joindre la capture du reçu (facultatif)' : 'Capture jointe'),
            ),
          ),
        ]),
        champs: const [
          Champ('provider_transaction_id', 'Numéro de transaction', obligatoire: true, maxLongueur: 100),
          Champ('amount', 'Montant envoyé', type: TypeChamp.montant, obligatoire: true, min: 1),
          Champ('payer_phone', 'Numéro qui a payé', type: TypeChamp.telephone),
        ],
        libelleEnvoi: 'Déclarer le paiement',
        messageSucces: 'Paiement déclaré : votre propriétaire va le vérifier.',
        envoyer: (c) => api.upload<Map<String, dynamic>>('/locataire/paiements/preuves',
            cheminFichier: photo, champs: {...c, 'rent_schedule_id': echeance['id'], 'wallet': moyen['wallet']}, idempotence: cle),
      ),
    );
    if (r != null && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Payer',
      charger: () => api.get<Map<String, dynamic>>('/locataire/paiements/moyens', query: {'lease_id': bailId}, cache: false),
      builder: (context, data, _) {
        final m = data['methods'] as Map;
        final integres = ((m['integre'] as List?) ?? []).map((e) => '$e').toList();
        final preuves = ((m['preuve'] as List?) ?? []).cast<Map>();
        return Scaffold(
          appBar: AppBar(title: const Text('Payer mon loyer')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Section(children: [
              Text('${echeance['label']}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Montant(_reste, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              Text('Bénéficiaire : ${m['beneficiaire']}'),
            ]),
            const SizedBox(height: AppTheme.espaceLg),
            if (integres.isNotEmpty) ...[
              Text('Payer maintenant', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final w in integres)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => _integre(context, w),
                    icon: const Icon(Icons.phone_iphone),
                    label: Text('Payer avec ${refs.libelle('portefeuille', w)}'),
                  ),
                ),
              const SizedBox(height: AppTheme.espaceLg),
            ],
            if (preuves.isNotEmpty) ...[
              Text("J'ai déjà payé directement", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final p in preuves)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_outlined),
                    title: Text('${p['label'] ?? refs.libelle('portefeuille', p['wallet'] as String?)}'),
                    subtitle: Text('Envoyer au ${p['account_number']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _preuve(context, p),
                  ),
                ),
              const SizedBox(height: AppTheme.espaceLg),
            ],
            if (m['especes'] == true)
              const Encadre('Vous pouvez aussi payer en espèces à votre propriétaire : il enregistre le paiement et votre quittance apparaît ici.'),
            if (integres.isEmpty && preuves.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Encadre('Votre propriétaire n’a pas encore activé le paiement par Wave ou Orange Money.', ton: TonStatut.avertissement),
              ),
          ]),
        );
      },
    );
  }
}

/// Suivi d'un paiement en ligne : la confirmation vient du serveur (webhook PayDunya).
class SuiviTransactionScreen extends StatefulWidget {
  const SuiviTransactionScreen({super.key, required this.id, this.checkoutUrl});
  final String id;
  final String? checkoutUrl;

  @override
  State<SuiviTransactionScreen> createState() => _SuiviTransactionScreenState();
}

class _SuiviTransactionScreenState extends State<SuiviTransactionScreen> with WidgetsBindingObserver {
  Map? _t;
  Timer? _minuterie;
  int _essais = 0;

  static const _finaux = ['confirmee', 'echouee', 'annulee', 'remboursee', 'a_rapprocher'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verifier();
    // Vérification espacée pendant 5 minutes, puis à la demande
    _minuterie = Timer.periodic(const Duration(seconds: 5), (_) {
      if (++_essais > 60 || _finaux.contains(_t?['status'])) {
        _minuterie?.cancel();
      } else {
        _verifier();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) _verifier();
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _verifier() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/locataire/paiements/transactions/${widget.id}', cache: false);
      if (mounted) setState(() => _t = r['transaction'] as Map);
    } catch (_) {
      // Nouvelle tentative au prochain passage
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final statut = t?['status'] as String?;
    final (icone, titre, texte, ton) = switch (statut) {
      'confirmee' => (Icons.check_circle_outline, 'Paiement confirmé', 'Merci ! Votre quittance est disponible dans « Mes quittances ».', TonStatut.succes),
      'echouee' || 'annulee' => (Icons.error_outline, 'Paiement non abouti', 'Aucun montant n’a été débité. Vous pouvez réessayer.', TonStatut.danger),
      'a_rapprocher' => (Icons.schedule, 'Paiement reçu', 'Votre propriétaire doit l’associer à votre échéance.', TonStatut.avertissement),
      _ => (Icons.hourglass_top, 'En attente de confirmation', 'Validez le paiement dans votre application Wave / Orange Money, puis revenez ici.', TonStatut.info),
    };
    final c = couleursDuTon(context, ton);
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi du paiement')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Icon(icone, size: 72, color: c.texte),
        const SizedBox(height: 16),
        Text(titre, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(texte, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (t != null)
          Section(children: [
            Ligne('Montant', montant(t['amount'] as num?)),
            Ligne('Référence', '${t['reference']}'),
            Ligne('Statut', null, widget: Statut(FamilleStatut.transaction, 'statut_transaction', statut)),
          ]),
        const SizedBox(height: 24),
        if (!_finaux.contains(statut) && widget.checkoutUrl != null)
          OutlinedButton(
            onPressed: () => launchUrl(Uri.parse(widget.checkoutUrl!), mode: LaunchMode.externalApplication),
            child: const Text('Rouvrir la page de paiement'),
          ),
        TextButton(onPressed: _verifier, child: const Text('Vérifier maintenant')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Terminer')),
      ]),
    );
  }
}

/// Ouvre la page de paiement puis l'écran de suivi.
Future<void> ouvrirPaiement(BuildContext context, String transactionId, String checkoutUrl) async {
  await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SuiviTransactionScreen(id: transactionId, checkoutUrl: checkoutUrl)));
}
