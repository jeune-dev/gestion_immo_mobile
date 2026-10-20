import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/statuts.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'package:gestion_immo_mobile/core/widgets/actions.dart';
import 'package:gestion_immo_mobile/core/widgets/base.dart';
import 'package:gestion_immo_mobile/core/widgets/chargement.dart';
import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/account/presentation/bloc/account_bloc.dart';
import 'package:gestion_immo_mobile/features/account/presentation/bloc/account_event.dart';
import 'package:gestion_immo_mobile/features/account/presentation/bloc/account_state.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountBloc>()..add(LoadSessions()),
      child: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountActionError) {
            afficherErreurApi(context, state.failure);
          } else if (state is AccountSuccess) {
            afficherSucces(context, state.message);
          }
        },
        buildWhen: (_, state) =>
            state is AccountInitial ||
            state is SessionsLoaded ||
            state is AccountError,
        builder: (context, state) {
          if (state is! SessionsLoaded) {
            return VueChargement(
              titre: 'Appareils connectés',
              failure: state is AccountError ? state.failure : null,
              onReessayer: () =>
                  context.read<AccountBloc>().add(LoadSessions()),
            );
          }
          final sessions = state.sessions;
          final bloc = context.read<AccountBloc>();
          return Scaffold(
            appBar: AppBar(title: const Text('Appareils connectés')),
            body: RefreshIndicator(
              onRefresh: () async => bloc.add(LoadSessions()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Column(
                      children: [
                        for (final session in sessions)
                          ListTile(
                            leading: Icon(session.plateforme == 'web'
                                ? Icons.computer
                                : Icons.smartphone),
                            title: Text(session.nomAppareil ??
                                refs.libelle(
                                    'plateforme_appareil', session.plateforme)),
                            subtitle: Text(
                                'Actif ${ilYa(session.derniereUtilisation)}${session.courante ? ' · cet appareil' : ''}'),
                            trailing: session.courante
                                ? const Pastille('Cet appareil',
                                    ton: TonStatut.info)
                                : IconButton(
                                    tooltip: 'Déconnecter',
                                    icon: const Icon(Icons.logout),
                                    onPressed: () => bloc
                                        .add(RevoquerSessionEvent(session.id)),
                                  ),
                          ),
                      ],
                    ),
                  ),
                  if (sessions.any((s) => !s.courante)) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await confirmer(
                          context,
                          titre: 'Déconnecter les autres appareils',
                          message: 'Toutes les autres sessions seront fermées.',
                          danger: true,
                        );
                        if (ok != null) bloc.add(RevoquerAutresSessionsEvent());
                      },
                      icon: const Icon(Icons.phonelink_erase),
                      label: const Text('Déconnecter tous les autres appareils'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
