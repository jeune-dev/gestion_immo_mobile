# Gestion Immo — Application mobile (propriétaires et locataires)

Application Flutter du SaaS de gestion immobilière, branchée sur l'API
`gestion_immo_back` selon `CONTRAT-API-MOBILE.md` et habillée selon
`CHARTE-GRAPHIQUE-MOBILE.md` (thème de la charte copié tel quel dans `lib/theme/`).

## Lancer

```bash
cp .env.example .env     # une seule fois ; API_URL pointe sur le backend local
flutter pub get
flutter run
```

L'URL de l'API est lue dans `.env` (`API_URL`). Sur l'émulateur Android,
`localhost` est remplacé automatiquement par `10.0.2.2` (la machine hôte). Sur un
téléphone réel, mettez l'adresse IP du Mac (`http://192.168.x.x:5010/api/v1`) et
lancez l'API avec `HOST=0.0.0.0`. En production, `--dart-define=API_URL=https://…`
prend le pas sur le `.env`.

> iOS : le projet est dans `~/Documents`, synchronisé par iCloud, qui ajoute des
> attributs aux dossiers `.framework` : la signature échoue (« Exited with status
> code 255 »). `build/` est donc un lien vers `~/Library/Caches/gestion_immo_mobile-build`.
> Après un `flutter clean` (qui supprime le lien), relancez `bash tool/preparer-build.sh`.

## Comptes de démonstration (base locale peuplée par l'API)

| Rôle | Identifiant | Mot de passe |
|---|---|---|
| Propriétaires | `balla.diop@demo.sn`, `aminata.sow@demo.sn`, `moussa.fall@demo.sn` (ou `771110001`…) | `Demo2026Immo` |
| Locataire | `772221002` ou `772221003` | `Demo2026Immo` |

## Organisation

```
lib/core/api/        client Dio : enveloppe, refresh token tournant (une requête en vol),
                     erreurs par error.code, Idempotency-Key, cache de lecture hors ligne
lib/core/auth/       session (coffre sécurisé), connexion + double authentification
lib/core/sync/       file des créations hors ligne (dépenses, incidents) — § 34-35
lib/core/widgets/    listes paginées, formulaires déclaratifs, badges de statut, PDF
lib/features/auth/   connexion, inscription, mot de passe oublié, activation locataire
lib/features/proprietaire/  Accueil · Biens · Finances · Travaux · Profil (§ 36)
lib/features/locataire/     Accueil (PAYER) · Mon loyer · Demandes · Messages · Profil (§ 28)
```

## Reste à brancher

- Notifications push FCM : ajouter `firebase_messaging` + fichiers de configuration
  Firebase, puis `POST /compte/appareils` avec le jeton (route déjà prévue côté API).
- Icône et écran de lancement définitifs.
