import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestion_immo_mobile/injection_container.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/bloc/notifications_state.dart';

/// Compteur des notifications non lues (rafraîchi à chaque affichage).
class BoutonNotifications extends StatelessWidget {
  const BoutonNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()..add(LoadCompteurNotifications()),
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          final nonLues =
              state is CompteurNotificationsLoaded ? state.nonLues : 0;
          return Badge(
            isLabelVisible: nonLues > 0,
            label: Text(nonLues > 99 ? '99+' : '$nonLues'),
            child: const Icon(Icons.notifications_outlined),
          );
        },
      ),
    );
  }
}
