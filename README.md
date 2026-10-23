# Gestion Immo — Application mobile (propriétaires et locataires)

Application Flutter du SaaS de gestion immobilière, branchée sur l'API
`gestion_immo_back` (référence des routes : `gestion_immo_back/docs/API.md`, générée
depuis le routeur réel par `npm run doc:routes`). Thème de la charte graphique dans
`lib/core/theme/`, police Inter embarquée dans `assets/fonts/` (licence OFL).

## Lancer

```bash
cp config/.env.example config/.env   # facultatif ; API_URL pointe sur le backend local
flutter pub get
flutter run
```

L'URL de l'API est lue dans `config/.env` (`API_URL`, fichier facultatif et non
versionné ; à défaut : `http://localhost:3000/api/v1`). Sur l'émulateur Android,
`localhost` est remplacé automatiquement par `10.0.2.2` (la machine hôte). Sur un
téléphone réel, mettez l'adresse IP du Mac (`http://192.168.x.x:3000/api/v1`) et
lancez l'API avec `HOST=0.0.0.0`. En production, `--dart-define=API_URL=https://…`
prend le pas sur `config/.env`.

## Publier (Android)

Copier `android/key.properties.example` en `android/key.properties` et y indiquer
la clé de publication (jamais versionnée). Sans ce fichier, l'APK de release est
signée avec la clé de debug, refusée par le Play Store.

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
                       erreurs par error.code, Idempotency-Key, cache de lecture hors ligne
lib/core/services/     jetons (coffre sécurisé), file des créations hors ligne, référentiels
lib/core/connection/   état du réseau (synchronisation au retour de la connexion)
lib/core/widgets/      listes paginées, formulaires déclaratifs, badges de statut, PDF
lib/core/theme/        thème de la charte graphique
lib/injection_container.dart   enregistrement des dépendances (get_it)
lib/features/auth/     connexion, inscription, mot de passe oublié, activation locataire
lib/features/home/     accueils propriétaire et locataire (navigation par onglets)
lib/features/…         une fonctionnalité par dossier : immeuble, appartement, bail,
                       locataire, echeance, paiement, quittance, caution, depense, travaux,
                       incident, etat_des_lieux, messagerie, rapport, abonnement…
lib/features/espace_locataire/   écrans propres au locataire (payer, loyer, demandes)
```

## Reste à brancher

- Notifications push FCM : ajouter `firebase_messaging` + fichiers de configuration
  Firebase, puis `POST /compte/appareils` avec le jeton (route déjà prévue côté API).
- Icône et écran de lancement définitifs.
