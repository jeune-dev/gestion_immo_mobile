import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/services.dart';
import '../../../core/widgets/actions.dart';
import '../../../core/widgets/base.dart';
import '../../../core/widgets/chargement.dart';
import '../../../core/widgets/navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/statuts.dart';
import '../../commun/documents.dart';
import '../messagerie_screen.dart';
import 'bail_detail.dart';
import 'formulaires.dart';

class LocataireDetail extends StatelessWidget {
  const LocataireDetail({super.key, required this.id});
  final String id;

  /// Affiche le code d'invitation à transmettre au locataire (§ 5 option A).
  static Future<void> afficherInvitation(BuildContext context, Map invitation, Map locataire) {
    final code = '${invitation['code']}';
    final texte = 'Bonjour ${locataire['first_name']}, téléchargez l’application Gestion Immo et activez votre compte '
        'locataire avec le code $code et votre numéro ${locataire['phone']}. Code valable jusqu’au ${date(invitation['expires_at'] as String?)}.';
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Code d'invitation"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SelectableText(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 4).merge(chiffresFixes)),
          const SizedBox(height: AppTheme.espaceSm),
          Text('Valable jusqu’au ${date(invitation['expires_at'] as String?)}. Le locataire l’utilise avec son numéro de téléphone.',
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              afficherSucces(context, 'Code copié');
            },
            child: const Text('Copier'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              SharePlus.instance.share(ShareParams(text: texte));
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Locataire',
      charger: () => api.get<Map<String, dynamic>>('/locataires/$id'),
      builder: (context, data, recharger) {
        final t = Map<String, dynamic>.from(data['tenant'] as Map);
        final baux = ((t['leases'] as List?) ?? []).cast<Map<String, dynamic>>();
        final solde = (t['balance'] as Map?) ?? {};
        final invitation = t['pending_invitation'] as Map?;
        return Scaffold(
          appBar: AppBar(
            title: Text(nomComplet(t)),
            actions: [
              IconButton(
                tooltip: 'Écrire au locataire',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => ouvrir(context, ConversationScreen.proprietaire(locataireId: id, titre: nomComplet(t))),
              ),
              MenuActions(actions: [
                ('Modifier', () async {
                  if (await FormulairesBiens.locataire(context, existant: t) != null) recharger();
                }, false),
                ('Supprimer', () async {
                  final ok = await confirmer(context,
                      titre: 'Supprimer le locataire',
                      message: 'Un locataire qui a un historique (bail, paiements) ne peut pas être supprimé.',
                      action: 'Supprimer',
                      danger: true);
                  if (ok == null || !context.mounted) return;
                  final fait = await executer(context, () => api.delete<dynamic>('/locataires/$id').then((_) => true), succes: 'Locataire supprimé');
                  if (fait == true && context.mounted) Navigator.pop(context);
                }, true),
              ]),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: recharger,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Section(children: [
                Ligne('Téléphone', '${t['phone'] ?? ''}'),
                Ligne('E-mail', t['email'] as String?),
                Ligne("Pièce d'identité",
                    t['id_document_type'] == null ? null : '${refs.libelle('type_piece_identite', t['id_document_type'] as String?)} ${t['id_document_number'] ?? ''}'),
                Ligne('Compte application', null,
                    widget: t['account_active'] == true
                        ? const Pastille('Activé', ton: TonStatut.succes)
                        : Pastille(invitation == null ? 'Non activé' : 'Invitation envoyée', ton: TonStatut.neutre)),
                Ligne('WhatsApp', null,
                    widget: Pastille(t['whatsapp_consent'] == true ? 'Consentement donné' : 'Pas de consentement',
                        ton: t['whatsapp_consent'] == true ? TonStatut.succes : TonStatut.neutre)),
                if (t['notes'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${t['notes']}')),
                const SizedBox(height: AppTheme.espaceSm),
                Wrap(spacing: AppTheme.espaceSm, runSpacing: AppTheme.espaceSm, children: [
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${t['phone']}')),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Appeler'),
                  ),
                  if (t['account_active'] != true)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final r = await executer(context, () => api.post<Map<String, dynamic>>('/locataires/$id/invitation'));
                        if (r != null && context.mounted) {
                          await afficherInvitation(context, r['invitation'] as Map, t);
                          recharger();
                        }
                      },
                      icon: const Icon(Icons.key_outlined),
                      label: Text(invitation == null ? 'Inviter dans l’application' : 'Nouveau code'),
                    ),
                  if (t['whatsapp_consent'] != true)
                    TextButton(
                      onPressed: () async {
                        final ok = await confirmer(context,
                            titre: 'Consentement WhatsApp',
                            message: 'Confirmez que le locataire a accepté de recevoir relances et confirmations par WhatsApp.');
                        if (ok == null || !context.mounted) return;
                        await executer(context, () => api.post<dynamic>('/locataires/$id/consentement-whatsapp', body: {'accorde': true}),
                            succes: 'Consentement enregistré');
                        recharger();
                      },
                      child: const Text('Enregistrer le consentement WhatsApp'),
                    ),
                ]),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Solde', children: [
                Ligne('Reste dû', montant(solde['reste_du'] as num?)),
                Ligne('Impayés', montant(solde['impayes'] as num?)),
                Ligne('Échéances en retard', '${solde['echeances_en_retard'] ?? 0}'),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: 'Baux',
                padding: false,
                children: baux.isEmpty
                    ? [const ListTile(title: Text('Aucun bail'))]
                    : [
                        for (final b in baux)
                          ListTile(
                            title: Text('${b['reference']} · ${(b['apartment'] as Map?)?['number'] ?? ''}'),
                            subtitle: Text('${((b['apartment'] as Map?)?['building'] as Map?)?['name'] ?? ''} · ${montant(b['rent_amount'] as num?)}'),
                            trailing: Statut(FamilleStatut.bail, 'statut_bail', b['status'] as String?),
                            onTap: () async {
                              await ouvrir(context, BailDetail(id: '${b['id']}'));
                              recharger();
                            },
                          ),
                      ],
              ),
              const SizedBox(height: AppTheme.espaceLg),
              Section(titre: 'Derniers paiements', padding: false, children: [
                for (final p in ((t['recent_payments'] as List?) ?? []).cast<Map>())
                  ListTile(
                    dense: true,
                    title: Text('${p['reference']}'),
                    subtitle: Text('${date(p['paid_on'] as String?)} · ${refs.libelle('mode_paiement', p['method'] as String?)}'),
                    trailing: Montant(p['amount'] as num?),
                  ),
                if (((t['recent_payments'] as List?) ?? []).isEmpty) const ListTile(title: Text('Aucun paiement')),
              ]),
              const SizedBox(height: AppTheme.espaceLg),
              SectionDocuments(type: 'tenant', id: id),
            ]),
          ),
        );
      },
    );
  }
}
