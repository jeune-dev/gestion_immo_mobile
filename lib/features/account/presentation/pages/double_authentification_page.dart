import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/account/presentation/bloc/account_bloc.dart';
import 'package:gestion_immo_mobile/features/account/presentation/bloc/account_event.dart';
import 'package:gestion_immo_mobile/features/account/presentation/bloc/account_state.dart';

/// Double authentification facultative (propriétaire, locataire) : la clé est
/// ajoutée à l'application d'authentification par le lien `otpauth://` ou à la main.
class DoubleAuthentificationPage extends StatelessWidget {
  const DoubleAuthentificationPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<AccountBloc>(), child: const _Contenu());
}

class _Contenu extends StatelessWidget {
  const _Contenu();

  Future<String?> _motDePasse(BuildContext context) => confirmer(
        context,
        titre: 'Confirmez votre mot de passe',
        message: '',
        motif: true,
        libelleMotif: 'Mot de passe',
        minMotif: 1,
        action: 'Continuer',
        masque: true,
      );

  Future<String?> _code(BuildContext context, String titre) =>
      confirmer(context,
          titre: titre,
          message: '',
          motif: true,
          libelleMotif: 'Code à 6 chiffres',
          minMotif: 6);

  @override
  Widget build(BuildContext context) {
    final active = context.select((AuthBloc b) =>
        b.state.compte?.utilisateur.doubleAuthentificationActive ?? false);
    final bloc = context.read<AccountBloc>();
    return BlocConsumer<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountActionError) {
          afficherErreurApi(context, state.failure);
        } else if (state is AccountSuccess) {
          afficherSucces(context, state.message);
          if (state.compteModifie) {
            context.read<AuthBloc>().add(CompteRechargeDemande());
          }
        }
      },
      // Messages ponctuels : l'écran garde la clé ou les codes affichés.
      buildWhen: (_, state) =>
          state is AccountInitial ||
          state is SecretMfaLoaded ||
          state is CodesSecoursLoaded,
      builder: (context, state) {
        final codes = state is CodesSecoursLoaded ? state.codes : null;
        final secret = state is SecretMfaLoaded ? state.secret : null;
        return Scaffold(
          appBar: AppBar(title: const Text('Double authentification')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (codes != null) ...[
                const Encadre(
                    'Conservez ces codes de secours en lieu sûr : ils ne seront plus affichés.',
                    ton: TonStatut.avertissement),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(codes.join('\n'),
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            height: 1.6)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: codes.join('\n')));
                    afficherSucces(context, 'Codes copiés');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
              ] else if (active) ...[
                const Encadre(
                    'La double authentification est activée sur votre compte.',
                    ton: TonStatut.succes),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    final mdp = await _motDePasse(context);
                    if (mdp == null || !context.mounted) return;
                    final code = await _code(context, "Code de l'application");
                    if (code != null) {
                      bloc.add(RegenererCodesSecoursEvent(
                          motDePasse: mdp, code: code));
                    }
                  },
                  child: const Text('Générer de nouveaux codes de secours'),
                ),
                TextButton(
                  onPressed: () async {
                    final mdp = await _motDePasse(context);
                    if (mdp == null || !context.mounted) return;
                    final code = await _code(context, "Code de l'application");
                    if (code != null) {
                      bloc.add(DesactiverMfaEvent(motDePasse: mdp, code: code));
                    }
                  },
                  child: Text('Désactiver',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              ] else if (secret == null) ...[
                const Text(
                  'Protégez votre compte : à chaque connexion, un code à 6 chiffres de votre application '
                  "d'authentification (Google Authenticator, Microsoft Authenticator…) vous sera demandé.",
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final mdp = await _motDePasse(context);
                    if (mdp != null) bloc.add(InitialiserMfaEvent(mdp));
                  },
                  child: const Text('Activer'),
                ),
              ] else ...[
                const Text(
                    "1. Ajoutez la clé à votre application d'authentification :"),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => launchUrl(Uri.parse(secret.otpauthUrl),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Ouvrir l'application d'authentification"),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: SelectableText(secret.secret,
                        style: const TextStyle(fontFamily: 'monospace')),
                    subtitle: const Text('ou saisissez cette clé à la main'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: secret.secret)),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.espaceLg),
                const Text('2. Saisissez le code affiché :'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final code = await _code(context, 'Code de vérification');
                    if (code != null) bloc.add(ActiverMfaEvent(code));
                  },
                  child: const Text('Valider'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
