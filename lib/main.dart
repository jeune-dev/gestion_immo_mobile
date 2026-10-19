import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_router.dart';
import 'core/auth/session_cubit.dart';
import 'core/services.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuration (.env) AVANT le premier accès aux services : l'URL de l'API en dépend
  await dotenv.load(fileName: '.env', isOptional: true);
  await initializeDateFormatting('fr');
  await Services.fileAttente.charger();
  // Les référentiels (libellés des statuts) se chargent en arrière-plan, depuis le cache d'abord
  Services.referentiels.charger();
  final session = SessionCubit()..demarrer();
  runApp(GestionImmoApp(session: session));
}

/// Police Inter (charte § 2) appliquée au thème de la charte, sans le modifier.
ThemeData _avecInter(ThemeData t) => t.copyWith(
      textTheme: GoogleFonts.interTextTheme(t.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(t.primaryTextTheme),
    );

class GestionImmoApp extends StatefulWidget {
  const GestionImmoApp({super.key, required this.session});
  final SessionCubit session;

  @override
  State<GestionImmoApp> createState() => _GestionImmoAppState();
}

class _GestionImmoAppState extends State<GestionImmoApp> with WidgetsBindingObserver {
  late final _router = creerRouteur(widget.session);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour au premier plan : on tente de synchroniser les opérations créées hors ligne.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed && widget.session.state.etat == EtatSession.connecte) {
      Services.fileAttente.synchroniser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.session,
      child: MaterialApp.router(
        title: 'Gestion Immo',
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
      ),
    );
  }
}
