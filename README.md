# Gestion Immo — Application mobile (propriétaires et locataires)

Application Flutter du SaaS de gestion immobilière, branchée sur l'API
`gestion_immo_back` (référence des routes : `gestion_immo_back/docs/API.md`, générée
depuis le routeur réel par `npm run doc:routes`). Thème de la charte graphique dans
`lib/core/theme/`, police Inter embarquée dans `assets/fonts/` (licence OFL).

## Lancer

```bash
cp config/.env.example config/.env   # facultatif ; API_URL pointe sur le backend local
flutter pub get
flutter run --dart-define-from-file=config/.env   # ou simplement `flutter run`
```

L'URL de l'API est fixée à la compilation : `config/.env` (`API_URL`, fichier
facultatif et non versionné) passé par `--dart-define-from-file`, à défaut
`http://localhost:3000/api/v1`. Aucun fichier de configuration n'est embarqué
dans l'application. Sur l'émulateur Android,
`localhost` est remplacé automatiquement par `10.0.2.2` (la machine hôte). Sur un
téléphone réel, mettez l'adresse IP du Mac (`http://192.168.x.x:3000/api/v1`) et
lancez l'API avec `HOST=0.0.0.0`. En production, `--dart-define=API_URL=https://…`
est obligatoire : un build de publication sans URL `https` est refusé.

## Publier

### Android

Copier `android/key.properties.example` en `android/key.properties` et y indiquer
la clé de publication (jamais versionnée). Sans ce fichier, le build de release
échoue : c'est voulu, un `.aab` signé avec la clé de debug est refusé par le Play
Store, mais seulement après le temps de construction et de téléversement.

```bash
flutter build appbundle --release --dart-define-from-file=config/.env
```

Pour vérifier que la configuration tient sans posséder la clé :
`ALLOW_DEBUG_SIGNING=true flutter build appbundle --release …` — le `.aab` produit
n'est alors pas publiable, et un avertissement le dit.

### iOS

```bash
cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install
```

Le `LANG` n'est pas décoratif : sans terminal en UTF-8, CocoaPods échoue sur
`Unicode Normalization not appropriate for ASCII-8BIT`.

Puis, dans Xcode — **l'espace de travail, pas le projet**, sinon les pods ne sont
pas liés :

```bash
open ios/Runner.xcworkspace
```

La configuration Release porte deux phases de build maison : « Contrôles de
publication » (refus sans `API_URL` en https, retrait des autorisations de
développement de l'`Info.plist`) et « Crashlytics : envoi des symboles ».

## Notifications push

La chaîne complète : jeton FCM enregistré auprès de l'API (`PushService`), canal
Android créé par `MainActivity.kt` et nommé dans le manifeste, entitlement
`aps-environment` côté iOS, et ouverture de l'écran concerné quand l'utilisateur
appuie sur la notification (`PushService._ouvrir`, par le même chemin que la liste
interne).

Désactivable pour un build particulier : `--dart-define=PUSH_ACTIVE=false`.

Deux choses se font en dehors du dépôt, et sans elles rien n'arrive :

- **Apple** : developer.apple.com → Identifiers → `sn.gestionimmo.gestionImmoMobile`
  → cocher « Push Notifications ». Puis créer une clé APNs (Keys) et la téléverser
  dans la console Firebase → Paramètres du projet → Cloud Messaging.
- **Android** : rien de plus, `google-services.json` est dans le dépôt.

Une notification reçue **application ouverte** n'affiche pas de bannière : le
backend envoie une charge `notification`, que ni Android ni iOS ne dessinent dans
ce cas. La pastille et l'écran de notifications tiennent ce rôle. Dessiner la
bannière soi-même demanderait `flutter_local_notifications`.

## Remontée des erreurs

`installerRemonteeErreurs()` pose trois filets avant `runApp` (erreurs du
framework, erreurs asynchrones, écran de remplacement en release) et
`demarrerFirebase()` démarre Crashlytics. Ce qui part : le libellé, le type de
l'erreur, la pile d'appels et l'identifiant du compte. Jamais un nom, un e-mail,
un téléphone, ni le corps d'une requête — d'où `journalErreur('ce qui a échoué',
e, pile)` plutôt que de jeter l'objet entier.

Rien n'est envoyé en débogage : sinon chaque rechargement à chaud remplirait la
console d'incidents qui n'existent pas.

À faire une fois dans la console Firebase : activer Crashlytics pour le projet.
Le tableau de bord n'apparaît qu'au premier incident reçu.

> iOS : le projet est dans `~/Documents`, synchronisé par iCloud, qui ajoute des
> attributs aux dossiers `.framework` : la signature échoue (« Exited with status
> code 255 »). `build/` est donc un lien vers `~/Library/Caches/gestion_immo_mobile-build`.
> Après un `flutter clean` (qui supprime le lien), relancez `bash tool/preparer-build.sh`.

## Comptes de test

La base locale ne contient aucun compte de démonstration. Pour tester :

- propriétaire : « Je suis propriétaire : créer mon compte » sur l'écran de connexion ;
- locataire : créé et invité par un propriétaire (fiche locataire → invitation), puis
  « Je suis locataire : j'ai un code d'invitation ».

## Vérifier l'accord avec l'API

`tool/e2e_mobile.js` rejoue les appels de l'application (mêmes chemins, mêmes corps)
contre une API lancée sur une base de **test** (il crée des comptes et des données) :

```bash
NODE_PATH=../gestion_immo_back/node_modules API=http://127.0.0.1:5010/api/v1 node tool/e2e_mobile.js
```

## Organisation

Architecture « clean » reprise de Sign : chaque fonctionnalité a ses couches
`data/` (API, modèles), `domain/` (entités, cas d'usage) et `presentation/` (blocs, pages).

```
lib/core/network/      client Dio : enveloppe, refresh token tournant (une requête en vol),
                       erreurs par error.code, Idempotency-Key
lib/core/services/     jetons (coffre sécurisé), référentiels, nettoyage des anciennes données locales
lib/core/widgets/      listes paginées, fiches chargées par identifiant, formulaires
                       déclaratifs, badges de statut, PDF
lib/core/errors/       échecs normalisés ; appelApi() pour tout appel d'un dépôt
lib/core/theme/        thème de la charte graphique
lib/injection_container.dart   enregistrement des dépendances (get_it)
lib/features/auth/     connexion, inscription, mot de passe oublié, activation locataire
lib/features/home/     accueils propriétaire et locataire (navigation par onglets)
lib/features/…         une fonctionnalité par dossier : immeuble, appartement, bail,
                       locataire, echeance, paiement, quittance, caution, depense, travaux,
                       incident, etat_des_lieux, messagerie, rapport, abonnement…
lib/features/espace_locataire/   écrans propres au locataire (payer, loyer, demandes)
```

### Gestion de l'état : quel outil pour quel écran

- **Liste paginée** de l'API → `ListePaginee` (filtres, chargement au défilement,
  tirer-pour-rafraîchir).
- **Fiche lue par identifiant**, éventuellement rechargée après une action →
  `FicheChargee` (chargement, erreur avec « Réessayer », puis la fiche).
- **Écran avec plusieurs états ou actions enchaînées** (connexion, paiement, état des
  lieux, bail…) → un Bloc/Cubit dans `presentation/bloc/`, testé sans interface.
- **Action ponctuelle** depuis un écran (annuler, encaisser) → `reussir()` /
  `executer()` de `core/widgets/actions.dart`, qui affichent le succès ou l'erreur.

Les écrans obtiennent leurs cas d'usage par `sl<…>()` (get_it) ; un dépôt n'est jamais
appelé directement depuis la présentation. Dans les tests, enregistrer un faux dépôt
dans `GetIt.instance` (voir `test/fiches_detail_test.dart`).

## Reste à brancher

- Icône et écran de lancement définitifs.

## Notifications push

Elles restent inactives tant que l'application n'est pas construite avec
`--dart-define=PUSH_ACTIVE=true`. Pour les activer :

1. déposer `android/app/google-services.json` et `ios/Runner/GoogleService-Info.plist` ;
2. activer la capacité « Push Notifications » et la clé APNs côté iOS ;
3. construire avec le `--dart-define` ci-dessus.

## Version publiée

`--dart-define=API_URL=https://…` est obligatoire : sans lui, le build de publication
échoue (Gradle sur Android, phase « Contrôles de publication » sur iOS, qui retire aussi
de l'Info.plist les autorisations réseau local réservées au développement). Sur Android,
`android/key.properties` est obligatoire (`ALLOW_DEBUG_SIGNING=true` autorise la clé de
debug pour un essai local).
