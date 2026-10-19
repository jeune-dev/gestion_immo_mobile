import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/session_cubit.dart';
import '../../core/format.dart';
import '../../core/referentiels.dart';
import '../../core/services.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/base.dart';
import '../../core/widgets/chargement.dart';
import '../../core/widgets/formulaire.dart';
import '../../core/widgets/navigation.dart';
import '../../theme/app_theme.dart';
import '../../theme/statuts.dart';
import '../auth/changer_mot_de_passe_screen.dart';

/// Modification du profil (`PATCH /compte`) ; le mot de passe est exigé pour changer d'e-mail.
Future<void> modifierCompte(BuildContext context) async {
  final cubit = context.read<SessionCubit>();
  final u = cubit.state.user ?? {};
  final r = await EcranFormulaire.ouvrir<Object>(
    context,
    EcranFormulaire(
      titre: 'Mon profil',
      initial: u,
      champs: [
        const Champ('first_name', 'Prénom', obligatoire: true, maxLongueur: 80),
        const Champ('last_name', 'Nom', obligatoire: true, maxLongueur: 80),
        const Champ('email', 'E-mail', type: TypeChamp.email),
        const Champ('language', 'Langue', type: TypeChamp.selection, options: [OptionRef('fr', 'Français'), OptionRef('en', 'Anglais')]),
        const Champ('current_password', 'Mot de passe actuel', type: TypeChamp.motDePasse, indice: "Uniquement pour changer d'e-mail"),
      ],
      messageSucces: 'Profil mis à jour',
      envoyer: (c) async {
        if (c['email'] == u['email']) c.remove('email');
        if (c['current_password'] == null) c.remove('current_password');
        await api.patch<dynamic>('/compte', body: c);
        await cubit.chargerCompte();
        return true;
      },
    ),
  );
  if (r == null) return;
}

/// Sécurité du compte : mot de passe, double authentification, appareils connectés.
class SecuriteScreen extends StatelessWidget {
  const SecuriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<SessionCubit>().state.user ?? {};
    final mfa = u['totp_enabled_at'] != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Changer de mot de passe'),
              subtitle: const Text('Les autres appareils seront déconnectés'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ouvrir(context, const ChangerMotDePasseScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Double authentification'),
              subtitle: Text(mfa ? 'Activée' : 'Un code à 6 chiffres en plus du mot de passe'),
              trailing: Pastille(mfa ? 'Activée' : 'Désactivée', ton: mfa ? TonStatut.succes : TonStatut.neutre),
              onTap: () => ouvrir(context, const DoubleAuthentificationScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text('Appareils connectés'),
              subtitle: const Text('Déconnexion à distance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ouvrir(context, const SessionsScreen()),
            ),
          ]),
        ),
      ]),
    );
  }
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Chargeur<Map<String, dynamic>>(
      page: true,
      titre: 'Appareils connectés',
      charger: () => api.get<Map<String, dynamic>>('/compte/sessions', cache: false),
      builder: (context, data, recharger) {
        final sessions = (data['sessions'] as List).cast<Map>();
        return Scaffold(
          appBar: AppBar(title: const Text('Appareils connectés')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: Column(children: [
                for (final s in sessions)
                  ListTile(
                    leading: Icon(s['platform'] == 'web' ? Icons.computer : Icons.smartphone),
                    title: Text('${s['device_name'] ?? refs.libelle('plateforme_appareil', s['platform'] as String?)}'),
                    subtitle: Text('Actif ${ilYa(s['last_used_at'] as String?)}${s['current'] == true ? ' · cet appareil' : ''}'),
                    trailing: s['current'] == true
                        ? const Pastille('Cet appareil', ton: TonStatut.info)
                        : IconButton(
                            tooltip: 'Déconnecter',
                            icon: const Icon(Icons.logout),
                            onPressed: () async {
                              await executer(context, () => api.delete<dynamic>('/compte/sessions/${s['id']}'), succes: 'Appareil déconnecté');
                              recharger();
                            },
                          ),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await confirmer(context, titre: 'Déconnecter les autres appareils', message: 'Toutes les autres sessions seront fermées.', danger: true);
                if (ok == null || !context.mounted) return;
                await executer(context, () => api.post<dynamic>('/compte/sessions/revoquer-toutes'), succes: 'Autres appareils déconnectés');
                recharger();
              },
              icon: const Icon(Icons.phonelink_erase),
              label: const Text('Déconnecter tous les autres appareils'),
            ),
          ]),
        );
      },
    );
  }
}

/// Double authentification facultative (propriétaire, locataire) : la clé est
/// ajoutée à l'application d'authentification par le lien `otpauth://` ou à la main.
class DoubleAuthentificationScreen extends StatefulWidget {
  const DoubleAuthentificationScreen({super.key});

  @override
  State<DoubleAuthentificationScreen> createState() => _DoubleAuthentificationScreenState();
}

class _DoubleAuthentificationScreenState extends State<DoubleAuthentificationScreen> {
  Map<String, dynamic>? _secret;
  List<String>? _codes;

  Future<String?> _motDePasse() => confirmer(context,
      titre: 'Confirmez votre mot de passe', message: '', motif: true, libelleMotif: 'Mot de passe', minMotif: 1, action: 'Continuer', masque: true);

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SessionCubit>();
    final active = cubit.state.user?['totp_enabled_at'] != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Double authentification')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_codes != null) ...[
          const Encadre('Conservez ces codes de secours en lieu sûr : ils ne seront plus affichés.', ton: TonStatut.avertissement),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_codes!.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 16, height: 1.6)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _codes!.join('\n')));
              afficherSucces(context, 'Codes copiés');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
          ),
        ] else if (active) ...[
          const Encadre('La double authentification est activée sur votre compte.', ton: TonStatut.succes),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final mdp = await _motDePasse();
              if (mdp == null || !context.mounted) return;
              final code = await confirmer(context, titre: "Code de l'application", message: '', motif: true, libelleMotif: 'Code à 6 chiffres', minMotif: 6);
              if (code == null || !context.mounted) return;
              final r = await executer(context, () => api.post<Map<String, dynamic>>('/compte/mfa/codes-secours', body: {'current_password': mdp, 'code': code}));
              if (r != null) setState(() => _codes = (r['codes_secours'] as List).cast<String>());
            },
            child: const Text('Générer de nouveaux codes de secours'),
          ),
          TextButton(
            onPressed: () async {
              final mdp = await _motDePasse();
              if (mdp == null || !context.mounted) return;
              final code = await confirmer(context, titre: "Code de l'application", message: '', motif: true, libelleMotif: 'Code à 6 chiffres', minMotif: 6);
              if (code == null || !context.mounted) return;
              await executer(context, () => api.post<dynamic>('/compte/mfa/desactiver', body: {'current_password': mdp, 'code': code}),
                  succes: 'Double authentification désactivée');
              await cubit.chargerCompte();
            },
            child: Text('Désactiver', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ] else if (_secret == null) ...[
          const Text('Protégez votre compte : à chaque connexion, un code à 6 chiffres de votre application '
              "d'authentification (Google Authenticator, Microsoft Authenticator…) vous sera demandé."),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final mdp = await _motDePasse();
              if (mdp == null || !context.mounted) return;
              final r = await executer(context, () => api.post<Map<String, dynamic>>('/compte/mfa/initialiser', body: {'current_password': mdp}));
              if (r != null) setState(() => _secret = r);
            },
            child: const Text('Activer'),
          ),
        ] else ...[
          const Text("1. Ajoutez la clé à votre application d'authentification :"),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => launchUrl(Uri.parse('${_secret!['otpauth_url']}'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text("Ouvrir l'application d'authentification"),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: SelectableText('${_secret!['secret']}', style: const TextStyle(fontFamily: 'monospace')),
              subtitle: const Text('ou saisissez cette clé à la main'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => Clipboard.setData(ClipboardData(text: '${_secret!['secret']}')),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.espaceLg),
          const Text('2. Saisissez le code affiché :'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final code = await confirmer(context, titre: 'Code de vérification', message: '', motif: true, libelleMotif: 'Code à 6 chiffres', minMotif: 6);
              if (code == null || !context.mounted) return;
              final r = await executer(context, () => api.post<Map<String, dynamic>>('/compte/mfa/activer', body: {'code': code}),
                  succes: 'Double authentification activée');
              if (r == null) return;
              await Services.session.enregistrer(access: r['access_token'] as String, refresh: r['refresh_token'] as String?);
              await cubit.chargerCompte();
              setState(() => _codes = (r['codes_secours'] as List).cast<String>());
            },
            child: const Text('Valider'),
          ),
        ],
      ]),
    );
  }
}
