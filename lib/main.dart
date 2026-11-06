import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gestion_immo_mobile/core/services/push_service.dart';
import 'package:gestion_immo_mobile/features/notifications/presentation/compteur_notifications.dart';
import 'package:gestion_immo_mobile/core/routes/app_router.dart';
import 'package:gestion_immo_mobile/core/services/nettoyage_local.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:gestion_immo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:gestion_immo_mobile/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter est embarquée (assets/fonts/) : aucun téléchargement depuis Google
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], ofl);
  });
  // Configuration (config/.env, facultatif) AVANT le premier accès aux services :
  // l'URL de l'API en dépend
  await dotenv.load(fileName: 'config/.env', isOptional: true);
  await initializeDateFormatting('fr');
  await nettoyerStockageLocal();
  await di.init();
  // Les référentiels (libellés des statuts) se chargent en arrière-plan, depuis le cache d'abord
  di.sl<ReferentielsService>().charger();
  runApp(const GestionImmoApp());
}

/// Police Inter (charte § 2) appliquée au thème de la charte, sans le modifier.
ThemeData _avecInter(ThemeData t) => t.copyWith(
  textTheme: GoogleFonts.interTextTheme(t.textTheme),
  primaryTextTheme: GoogleFonts.interTextTheme(t.primaryTextTheme),
);

class GestionImmoApp extends StatefulWidget {
  const GestionImmoApp({super.key});

  @override
  State<GestionImmoApp> createState() => _GestionImmoAppState();
}

class _GestionImmoAppState extends State<GestionImmoApp>
    with WidgetsBindingObserver {
  final _auth = di.sl<AuthBloc>()..add(AuthDemarree());
  late final _router = AppRouter.creer(_auth);
  late final StreamSubscription<AuthState> _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = _auth.stream.listen((etat) {
      if (etat.connecte) di.sl<PushService>().demarrer();
    });
  }

  @override
  void dispose() {
    _session.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _auth.close();
    super.dispose();
  }

  /// Retour au premier plan : le compteur de notifications se remet à jour.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) {
      if (_auth.state.connecte) CompteurNotifications.rafraichir();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'Kërimmo',
        debugShowCheckedModeBanner: false,
        theme: _avecInter(AppTheme.clair),
        darkTheme: _avecInter(AppTheme.sombre),
        themeMode: ThemeMode.system,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
        scrollBehavior: const _DefilementApp(),
        // Toucher en dehors d'un champ ferme le clavier, dans toute l'application.
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ?child,
              BlocSelector<AuthBloc, AuthState, bool>(
                selector: (etat) => etat.deconnexion,
                builder: (_, enCours) => enCours
                    ? const AbsorbPointer(
                        child: ColoredBox(
                          color: Colors.black26,
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Déconnexion en cours',
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faire défiler un écran ferme aussi le clavier.
class _DefilementApp extends MaterialScrollBehavior {
  const _DefilementApp();

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) => ScrollViewKeyboardDismissBehavior.onDrag;
}
