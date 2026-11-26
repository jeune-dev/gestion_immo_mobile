import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gestion_immo_mobile/core/utils/journal.dart';

/// Ce qui attrape les erreurs que personne n'a attrapées.
///
/// Sans ces trois filets, une exception levée pendant la construction d'un
/// écran produit, en version publiée, le panneau d'erreur de Flutter AVEC le
/// texte de l'exception — à l'écran du locataire. Et elle ne laisse aucune
/// trace ailleurs : ni dans la console Firebase, ni nulle part.
///
/// Les trois chemins sont distincts et aucun ne couvre les autres :
///  - [FlutterError.onError] : les erreurs du framework (construction, mise en
///    page, peinture). Ce sont elles qui donnent l'écran cassé ;
///  - [PlatformDispatcher.onError] : les erreurs asynchrones hors framework,
///    un `Future` dont personne n'attend le résultat ;
///  - [ErrorWidget.builder] : ce que l'utilisateur voit à la place du panneau
///    rouge, quand le mal est fait.
///
/// À appeler avant `runApp`, et avant tout ce qui peut lever.
void installerRemonteeErreurs() {
  final erreurFlutterInitiale = FlutterError.onError;

  FlutterError.onError = (details) {
    // Garde le comportement d'origine : en débogage, l'écran rouge et la
    // console restent le moyen le plus rapide de voir ce qui casse.
    erreurFlutterInitiale?.call(details);
    journalErreur(
      'erreur Flutter : ${details.context ?? 'sans contexte'}',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (erreur, pile) {
    journalErreur('erreur asynchrone non interceptée', erreur, pile);
    // `true` : l'erreur est considérée comme traitée, le processus continue.
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Une erreur est survenue. Fermez et rouvrez cet écran.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Démarre Firebase, donc Crashlytics, donc les notifications push.
///
/// Les deux fichiers de configuration sont dans le dépôt
/// (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) :
/// ils ne contiennent aucun secret, seulement l'identité du projet Firebase.
/// Si l'initialisation échoue malgré tout, l'application démarre quand même —
/// sans remontée et sans push, ce qui vaut mieux qu'un écran noir.
///
/// Appelée avant `runApp` : les gestionnaires d'erreurs posés par
/// [installerRemonteeErreurs] n'envoient rien tant que Firebase n'est pas là,
/// et le premier écran est justement un moment où des choses cassent.
Future<void> demarrerFirebase() async {
  try {
    await Firebase.initializeApp();
    // Rien ne part depuis un poste de développement : sinon chaque
    // rechargement à chaud remplit la console d'incidents qui n'existent pas.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  } catch (e) {
    journalDebug('Firebase indisponible : ni remontée d’erreurs, ni push ($e)');
  }
}
