import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/features/notifications/presentation/compteur_notifications.dart';

/// Cloche avec le nombre de notifications non lues, toujours à jour.
class BoutonNotifications extends StatefulWidget {
  const BoutonNotifications({super.key});

  @override
  State<BoutonNotifications> createState() => _BoutonNotificationsState();
}

class _BoutonNotificationsState extends State<BoutonNotifications> {
  @override
  void initState() {
    super.initState();
    CompteurNotifications.rafraichir();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: CompteurNotifications.valeur,
    builder: (context, nonLues, _) => Badge(
      isLabelVisible: nonLues > 0,
      label: Text(nonLues > 99 ? '99+' : '$nonLues'),
      child: const Icon(Icons.notifications_outlined),
    ),
  );
}
