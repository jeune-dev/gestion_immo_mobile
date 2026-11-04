import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/domain/usecases/consentir_whatsapp.dart';

/// Consentement du locataire aux messages WhatsApp de son propriétaire.
class WhatsappLocatairePage extends StatelessWidget {
  const WhatsappLocatairePage({super.key});

  Future<void> _choisir(BuildContext context, bool accorde) async {
    await reussir(
      context,
      () => sl<ConsentirWhatsapp>()(accorde: accorde),
      succes: accorde
          ? 'Relances WhatsApp activées'
          : 'Relances WhatsApp désactivées',
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget avantage(IconData icone, String texte) => Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.espaceMd),
      child: Row(
        children: [
          IconeOption(icone),
          const SizedBox(width: AppTheme.espaceMd),
          Expanded(
            child: Text(texte, style: TextStyle(color: p.texte, fontSize: 15)),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: const Text('Relances par WhatsApp'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.espaceLg),
        children: [
          Section(
            titre: 'Ce que vous recevrez',
            children: [
              avantage(
                Icons.schedule,
                'Les rappels avant et après l’échéance de votre loyer',
              ),
              avantage(
                Icons.check_circle_outline,
                'La confirmation de vos paiements',
              ),
              avantage(
                Icons.description_outlined,
                'L’avis lorsqu’un document est disponible',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.espaceLg),
          Text(
            'Votre choix peut être changé à tout moment. Vous continuez de recevoir vos notifications dans l’application.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.texteSecondaire, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          FilledButton(
            onPressed: () => _choisir(context, true),
            child: const Text('Activer les relances'),
          ),
          const SizedBox(height: AppTheme.espaceSm),
          OutlinedButton(
            onPressed: () => _choisir(context, false),
            child: const Text('Ne pas recevoir de messages'),
          ),
        ],
      ),
    );
  }
}
