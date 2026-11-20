# Logo TerangaLoc

`logo_terangaloc.svg` est la source : une tuile bleu nuit (`#0B2545`), une maison
blanche, une porte vert clair (`#7CC42A`). Le nom ne fait pas partie de l'image :
il est écrit par le widget `NomTerangaLoc` (« Teranga » bleu nuit, « Loc » vert),
pour rester net à toutes les tailles et suivre le mode sombre.

Les PNG en sont tirés :

| Fichier | Taille | Rôle |
| --- | --- | --- |
| `assets/images/picto_terangaloc.png` | 512 | Le picto sur fond clair (cartes, listes) |
| `assets/images/picto_terangaloc_clair.png` | 512 | Maison seule, sans tuile : sur les en-têtes bleu nuit, où la tuile ne se verrait pas |
| `assets/images/icone_app.png` | 1024 | Icône des deux boutiques, marine à bord perdu |
| `assets/images/icone_app_avant_plan.png` | 1024 | Avant-plan de l'icône adaptative Android |
| `ios/…/LaunchImage.imageset/*.png` | 140 / 280 / 420 | Écran de lancement iOS |
| `android/…/drawable-*/launch_image.png` | 140 → 560 | Écran de lancement Android |
| `gestion_immo_back/src/assets/logo_terangaloc.png` | 256 | En-tête des PDF (quittances, reçus) |

Le `#0B2545` de la tuile est aussi le bleu nuit de l'application
(`AppColors.marine`) : les en-têtes en dégradent vers `#14407A`, assez peu pour
que le picto blanc tienne d'un bout à l'autre du bandeau. `test/palette_test.dart`
garde ce contraste.

L'icône et l'avant-plan n'ont pas les coins arrondis : Android et iOS posent
eux-mêmes leur masque. L'avant-plan est plus petit que l'icône parce qu'Android
rogne l'icône adaptative en cercle.

Les deux écrans de lancement se posent sur du blanc (sur Android, sur la couleur
de fond du système à partir d'API 21) : c'est le picto à tuile qui y va, pas la
maison seule, qui disparaîtrait sur le blanc.

Après tout changement du logo :

```bash
dart run flutter_launcher_icons
```

`flutter_launcher_icons` ne touche pas aux écrans de lancement : les images
ci-dessus se refont à la main depuis `picto_terangaloc.png`.

```bash
sips -z 280 280 assets/images/picto_terangaloc.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png
```
