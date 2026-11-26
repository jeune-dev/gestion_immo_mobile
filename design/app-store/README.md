# Visuels de la fiche App Store — TerangaLoc

| Dossier | Contenu |
|---|---|
| `captures-brutes/` | Les captures telles que sorties du simulateur, **1320 × 2868** |
| `visuels/` | Ce qui part sur App Store Connect, même taille |
| `composer.py` | Le script qui pose les captures sur le fond de marque |

## La taille

`1320 × 2868` est la taille exigée par Apple pour l'affichage **6,9 pouces**
(iPhone 17 Pro Max, iPhone 18 Pro Max). C'est aussi la taille NATIVE de la
capture sur ces simulateurs : rien n'est redimensionné, donc rien n'est flou.

Les autres tailles de l'App Store en sont dérivées par Apple. Il n'y a donc
qu'un seul jeu d'images à produire.

## Prendre une capture brute

Sur le simulateur **iPhone 18 Pro Max** (les autres modèles donnent des tailles
plus petites, qu'Apple refuse pour ce format) :

```bash
xcrun simctl io booted screenshot design/app-store/captures-brutes/05-tableau-de-bord.png
```

Nommer les fichiers `NN-nom.png` : le numéro fixe l'ordre d'affichage sur la
fiche.

> **Les captures sont publiques.** Elles s'affichent en grand sur la page de
> l'App Store, et Google les indexe. Ne jamais photographier un compte réel :
> les noms des locataires, leurs téléphones, les montants des loyers et les
> adresses des biens y seraient lisibles par n'importe qui — et la politique de
> confidentialité promet exactement l'inverse. Un compte de démonstration aux
> données inventées, et lui seul.

## Régénérer les visuels

Pillow n'est pas une dépendance du projet Flutter, c'est un outil de design :

```bash
python3 -m venv .venv-design && .venv-design/bin/pip install Pillow
```

```bash
.venv-design/bin/python design/app-store/composer.py
```

Les titres sont dans la liste `VISUELS` en tête du script, une entrée par
capture. Deux règles qui ont déjà servi :

- **le titre ne répète pas ce que la capture affiche déjà.** Le premier essai
  titrait l'écran de connexion « Gérez, suivez, valorisez votre patrimoine »,
  qui est l'accroche imprimée sur cet écran : la phrase se lisait deux fois
  sur la même image ;
- **fond plat, jamais de dégradé.** Les captures portent leur propre fond
  clair ; sur un dégradé, leurs bords ressortent comme un collage. Même leçon
  que la bannière Play de SaamBiz.

Le titre rétrécit tout seul, de 88 px vers le bas, jusqu'à ce que la ligne la
plus longue tienne dans la largeur utile — sans quoi un titre un peu long
déborderait sans prévenir, et cela ne se verrait qu'à l'image finale.

## Les huit écrans visés

1. `01-tableau-de-bord` — les chiffres du mois
2. `02-biens` — immeubles et appartements avec leurs photos
3. `03-choix-espace` — propriétaire ou locataire ✅
4. `04-connexion` ✅
5. `05-bail` — loyer, charges, caution, échéances
6. `06-encaissement` — le geste quotidien, et la quittance
7. `07-espace-locataire` — son loyer et ce qui reste à payer
8. `08-incident` — signalé avec ses photos

Les six manquants demandent un compte de démonstration rempli : un compte vide
donne des écrans vides, ce qui est pire que pas de capture du tout.
