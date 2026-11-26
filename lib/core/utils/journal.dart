import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Les deux journaux de l'application.
///
/// ## Pourquoi deux, et pas un
///
/// Une trace de mise au point dit tout : jeton, corps de requête, réponse
/// entière. Ce détail n'a rien à faire sur le téléphone d'un locataire — il
/// resterait lisible par n'importe quelle application capable de lire le
/// journal système. [journalDebug] se tait donc en version publiée.
///
/// Mais se taire sur TOUT, c'est se priver de l'essentiel : quand un
/// propriétaire dit que « ça ne marche pas », il n'y a plus rien à regarder.
/// [journalErreur] parle donc en production aussi — sans la charge utile, avec
/// ce qui a échoué et où.
///
/// ## Ce qui part chez Crashlytics
///
/// Le libellé, le type de l'erreur et la pile d'appels. Jamais le corps d'une
/// requête ni une réponse de l'API : c'est pourquoi les appelants écrivent un
/// libellé en clair au lieu de jeter l'objet entier. Rien ne part si Firebase
/// n'est pas en place sur cet appareil.
const String _canal = 'TerangaLoc';

/// Vrai quand Firebase est initialisé sur cet appareil.
///
/// Appeler Crashlytics sans Firebase lève ; or ces fonctions sont appelées
/// depuis des `catch`, et une journalisation qui lève remplacerait l'erreur
/// qu'on voulait lire.
bool get _crashlyticsPret {
  if (kDebugMode) return false;
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Journal de diagnostic, écrit en développement seulement : `debugPrint`
/// n'est pas retiré des versions publiées, où un message d'exception peut
/// contenir une adresse ou une donnée personnelle.
void journalDebug(String message) {
  if (kDebugMode) debugPrint(message);
}

/// Une erreur, visible EN PRODUCTION AUSSI.
///
/// [quoi] dit ce qui a échoué, en clair et sans donnée personnelle :
/// « envoi de la quittance », « renouvellement de session ». L'erreur et la
/// pile suivent, c'est le reste du travail.
void journalErreur(String quoi, Object erreur, [StackTrace? pile]) {
  developer.log(
    quoi,
    name: _canal,
    error: erreur,
    stackTrace: pile,
    // 1000 = SEVERE : repérable d'un coup d'œil au milieu du reste.
    level: 1000,
  );

  if (!_crashlyticsPret) return;
  try {
    // `fatal: false` : l'application continue de tourner. Ce sont les
    // incidents non fatals de la console Firebase — un appel qui échoue, une
    // session qu'on n'a pas pu renouveler.
    FirebaseCrashlytics.instance.recordError(
      erreur,
      pile,
      reason: quoi,
      fatal: false,
    );
  } catch (e) {
    developer.log('remontée impossible', name: _canal, error: e);
  }
}

/// Rattache les incidents remontés à un compte.
///
/// Sans lui, une erreur dans la console n'est rattachée à personne : on voit
/// qu'une chose casse, sans pouvoir rappeler le propriétaire qui l'a subie.
/// L'identifiant seul — ni nom, ni e-mail, ni téléphone.
void suivreUtilisateur(String? id) {
  if (!_crashlyticsPret) return;
  try {
    FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
  } catch (_) {
    // Sans incidence sur ce que fait l'application.
  }
}
