import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/features/locataire/domain/entities/locataire.dart';

/// Affiche le code d'invitation à transmettre au locataire (§ 5 option A).
Future<void> afficherInvitation(
  BuildContext context,
  Invitation invitation,
  Locataire locataire,
) {
  final code = invitation.code;
  final expiration = date(invitation.expireLe);
  final texte = 'Bonjour ${locataire.prenom}, téléchargez l’application '
      'Gestion Immo et activez votre compte locataire avec le code $code et '
      'votre numéro ${locataire.telephone ?? ''}. Code valable jusqu’au '
      '$expiration.';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Code d'invitation"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ).merge(chiffresFixes),
          ),
          const SizedBox(height: AppTheme.espaceSm),
          Text(
            'Valable jusqu’au $expiration. Le locataire l’utilise avec son '
            'numéro de téléphone.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
