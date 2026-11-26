#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compose les visuels de la fiche App Store de TerangaLoc.

Prend les captures BRUTES du simulateur (1320 x 2868, taille native de
l'iPhone 6,9 pouces — exactement ce qu'Apple exige, aucun redimensionnement)
et les pose sur un fond de marque avec un titre.

    python3 design/app-store/composer.py

Entrée  : design/app-store/captures-brutes/NN-nom.png
Sortie  : design/app-store/visuels/NN-nom.png   (1320 x 2868)

Pourquoi un script et non une page HTML : une capture de navigateur dépend de
la taille de la fenêtre et du rapport de pixels de l'écran. Ici, ce qui sort
fait exactement 1320 x 2868 sur n'importe quelle machine.

Dépendance : Pillow. Elle n'est pas dans le projet Flutter, c'est un outil de
design, à installer à part :

    python3 -m venv .venv-design && .venv-design/bin/pip install Pillow
    .venv-design/bin/python design/app-store/composer.py
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
SOURCES = RACINE / 'design/app-store/captures-brutes'
SORTIE = RACINE / 'design/app-store/visuels'
POLICES = RACINE / 'assets/fonts'

# Taille imposée par Apple pour l'affichage 6,9 pouces (iPhone 17/18 Pro Max).
LARGEUR, HAUTEUR = 1320, 2868

# Charte TerangaLoc. Fond PLAT, jamais de dégradé : le logo et les captures
# portent déjà leur propre fond clair, et un dégradé derrière fait ressortir
# leurs bords comme un collage.
MARINE = (11, 37, 69)        # #0B2545, le fond de l'icône adaptative
VERT = (124, 196, 42)        # #7CC42A, le vert du logo
BLANC = (255, 255, 255)

MARGE_LATERALE = 120         # de chaque côté de la capture
HAUT_TITRE = 430             # hauteur du bloc de titre, au-dessus de la capture
RAYON = 56                   # coins arrondis de la capture

# Un visuel par capture : le fichier source, puis le titre, ligne par ligne.
# Les titres reprennent les mots de l'application elle-même quand elle en a
# (« Gérez, suivez, valorisez votre patrimoine » est l'accroche de l'écran de
# connexion) : inventer une autre promesse que celle que l'utilisateur lira
# ensuite dans l'app, c'est le début du mensonge.
VISUELS = [
    ('03-choix-espace.png', ['Propriétaire ou locataire,', 'chacun son espace']),
    # Le titre ne doit pas répéter ce que la capture AFFICHE DÉJÀ. Le premier
    # essai reprenait « Gérez, suivez, valorisez votre patrimoine », l'accroche
    # de l'écran de connexion : la même phrase se lisait deux fois sur la même
    # image, une fois en gros et une fois dans le téléphone. Le titre dit donc
    # autre chose de vrai.
    ('04-connexion.png', ['Un seul compte,', 'vos biens partout']),
]


def police(nom, taille):
    chemin = POLICES / nom
    if not chemin.exists():
        sys.exit(f'Police introuvable : {chemin}')
    return ImageFont.truetype(str(chemin), taille)


def largeur_texte(dessin, texte, fonte):
    g, h, d, b = dessin.textbbox((0, 0), texte, font=fonte)
    return d - g


def coins_arrondis(image, rayon):
    """Masque les quatre coins de l'image, en gardant l'alpha existant."""
    masque = Image.new('L', image.size, 0)
    ImageDraw.Draw(masque).rounded_rectangle(
        [(0, 0), (image.size[0] - 1, image.size[1] - 1)], radius=rayon, fill=255
    )
    arrondie = image.convert('RGBA')
    arrondie.putalpha(masque)
    return arrondie


def composer(source, lignes):
    capture = Image.open(source).convert('RGB')

    toile = Image.new('RGB', (LARGEUR, HAUTEUR), MARINE)
    dessin = ImageDraw.Draw(toile)

    # ── Le titre ────────────────────────────────────────────────────────────
    #
    # La taille part de 88 px et DESCEND jusqu'à ce que la ligne la plus longue
    # tienne dans la largeur utile. Fixer la taille une fois pour toutes
    # marchait tant que les titres se ressemblaient ; le jour où l'un est plus
    # long, il débordait sans prévenir, et cela ne se voit qu'à l'image finale.
    utile = LARGEUR - 2 * MARGE_LATERALE
    taille = 88
    while taille > 48:
        fonte = police('Inter-ExtraBold.ttf', taille)
        if max(largeur_texte(dessin, l, fonte) for l in lignes) <= utile:
            break
        taille -= 2
    interligne = int(taille * 1.22)

    # Filet vert au-dessus du titre : un rappel de marque qui ne dispute pas
    # l'attention au texte.
    haut_bloc = (HAUT_TITRE - len(lignes) * interligne) // 2
    dessin.rounded_rectangle(
        [(LARGEUR // 2 - 60, haut_bloc - 46), (LARGEUR // 2 + 60, haut_bloc - 36)],
        radius=5, fill=VERT,
    )

    y = haut_bloc
    for ligne in lignes:
        l = largeur_texte(dessin, ligne, fonte)
        dessin.text(((LARGEUR - l) // 2, y), ligne, font=fonte, fill=BLANC)
        y += interligne

    # ── La capture ──────────────────────────────────────────────────────────
    largeur_capture = LARGEUR - 2 * MARGE_LATERALE
    hauteur_capture = round(capture.height * largeur_capture / capture.width)
    capture = capture.resize((largeur_capture, hauteur_capture), Image.LANCZOS)
    capture = coins_arrondis(capture, RAYON)

    x, y = MARGE_LATERALE, HAUT_TITRE

    # Ombre portée : une version floutée du même rectangle, décalée vers le bas.
    # Sans elle, la capture est un rectangle collé sur un aplat ; avec, elle
    # repose sur le fond.
    ombre = Image.new('RGBA', (LARGEUR, HAUTEUR), (0, 0, 0, 0))
    ImageDraw.Draw(ombre).rounded_rectangle(
        [(x, y + 18), (x + largeur_capture, y + hauteur_capture + 18)],
        radius=RAYON, fill=(0, 0, 0, 150),
    )
    toile = Image.alpha_composite(
        toile.convert('RGBA'), ombre.filter(ImageFilter.GaussianBlur(26))
    )

    toile.paste(capture, (x, y), capture)
    return toile.convert('RGB')


def main():
    SORTIE.mkdir(parents=True, exist_ok=True)
    manquants = []
    for nom, lignes in VISUELS:
        source = SOURCES / nom
        if not source.exists():
            manquants.append(nom)
            continue
        image = composer(source, lignes)
        cible = SORTIE / nom
        image.save(cible, 'PNG', optimize=True)
        print(f'{cible.relative_to(RACINE)}  {image.width} x {image.height}')
    if manquants:
        print('\nCaptures brutes absentes : ' + ', '.join(manquants))
    print(f'\n{len(VISUELS) - len(manquants)} visuel(s) sur {len(VISUELS)}.')


if __name__ == '__main__':
    main()
