import 'package:gestion_immo_mobile/features/auth/presentation/widgets/confirmer_deconnexion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/navigation.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/modifier_profil.dart';
import 'package:gestion_immo_mobile/features/account/presentation/pages/securite_page.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/widgets/avatar_utilisateur.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gestion_immo_mobile/features/quittance/presentation/pages/quittances_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/caution_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/charges_locataire_page.dart';
import 'package:gestion_immo_mobile/features/espace_locataire/presentation/pages/whatsapp_locataire_page.dart';
import 'package:gestion_immo_mobile/core/widgets/logo.dart';
import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

/// Profil du locataire : caution, charges, quittances, consentement WhatsApp, sécurité.
class ProfilLocatairePage extends StatelessWidget {
  const ProfilLocatairePage({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.select((AuthBloc b) => b.state.compte?.utilisateur);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        leading: LogoBarre.siRacine(context),
        leadingWidth: LogoBarre.largeur,
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.espaceLg),
        children: [
          CarteMarque(
            child: Column(
              children: [
                const AvatarUtilisateur(taille: 84),
                const SizedBox(height: AppTheme.espaceMd),
                Text(
                  u?.nomComplet ?? '—',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.espaceXs),
                Text(
                  [u?.telephone, u?.email].whereType<String>().join('  ·  '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppTheme.espaceLg),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    minimumSize: const Size(0, 42),
                  ),
                  onPressed: () => modifierProfil(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier mon profil'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.espaceXl),
          GroupeOptions(
            titre: 'Mon logement',
            children: [
              TuileOption(
                icone: Icons.description_outlined,
                titre: 'Mes quittances',
                detail: 'Consulter et partager vos reçus de loyer',
                onTap: () => ouvrir(
                  context,
                  const QuittancesPage(espaceLocataire: true),
                ),
              ),
              TuileOption(
                icone: Icons.savings_outlined,
                titre: 'Ma caution',
                detail: 'Montants versés et retenues',
                onTap: () => ouvrir(context, const CautionLocatairePage()),
              ),
              TuileOption(
                icone: Icons.water_drop_outlined,
                titre: 'Mes charges',
                detail: 'Eau, électricité… refacturées',
                onTap: () => ouvrir(context, const ChargesLocatairePage()),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.espaceXl),
          GroupeOptions(
            titre: 'Préférences',
            children: [
              TuileOption(
                icone: Icons.notifications_outlined,
                titre: 'Notifications',
                onTap: () => ouvrir(context, const NotificationsPage()),
              ),
              TuileOption(
                icone: Icons.chat_outlined,
                titre: 'Relances par WhatsApp',
                detail: 'Rappels de loyer et confirmations',
                onTap: () => ouvrir(context, const WhatsappLocatairePage()),
              ),
              TuileOption(
                icone: Icons.lock_outline,
                titre: 'Sécurité',
                detail: 'Mot de passe et appareils connectés',
                onTap: () => ouvrir(context, const SecuritePage()),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.espaceXl),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => confirmerDeconnexion(context),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
