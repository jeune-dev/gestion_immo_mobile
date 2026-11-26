# TerangaLoc — fiche App Store (texte prêt à coller)

Longueurs vérifiées contre les limites d'Apple. App Store Connect →
TerangaLoc → App iOS 1.0, langue **Français**.

---

## 1. Informations de la page produit

### Nom — 10 / 30
```
TerangaLoc
```

### Sous-titre — 27 / 30
```
Gestion locative au Sénégal
```

### Texte promotionnel — 158 / 170
*(modifiable sans nouvelle version : à réserver aux annonces)*
```
Suivez vos loyers, vos baux et vos quittances depuis votre téléphone. Vos locataires signalent un incident et consultent leur solde depuis leur propre espace.
```

### Mots-clés — 86 / 100
*(séparés par des virgules, SANS espace : un espace compte comme un caractère.
Ne pas répéter le nom ni le sous-titre, Apple les indexe déjà.)*
```
loyer,bail,quittance,locataire,propriétaire,immobilier,location,caution,charges,impayé
```

### Nouveautés — version 1.0
```
Première version de TerangaLoc.
```

### Description — 1 939 / 4 000
```
TerangaLoc réunit la gestion de vos biens en location dans une seule application : immeubles, appartements, locataires, baux, loyers et quittances, à jour et consultables depuis votre téléphone.

POUR LE PROPRIÉTAIRE

• Vos biens — immeubles et appartements, avec leurs photos, leurs caractéristiques et leur occupation.
• Vos baux — durée, loyer, charges, caution, renouvellement, et le contrat signé conservé avec le bail.
• Les loyers au jour près — échéances, encaissements, retards : vous savez qui a payé et qui doit encore.
• Les quittances — générées depuis l'encaissement et envoyées au locataire, sans ressaisie.
• La caution — constitution, retenues justifiées, restitution.
• Les charges communes — eau, électricité, ordures : réparties entre les logements et refacturées.
• Les dépenses — par catégorie, pour savoir ce que chaque bien coûte réellement.
• Les incidents et les travaux — signalés par le locataire, confiés à un artisan, suivis jusqu'à la réception.
• Les états des lieux — entrée et sortie, pièce par pièce, photos à l'appui.
• Vos rapports — encaissements, impayés, rentabilité, sur la période de votre choix.

POUR LE LOCATAIRE

Un espace à lui, où il retrouve son logement et son bail, son loyer et ce qu'il reste à payer, ses quittances, sa caution, et où il signale un problème sans passer un appel. Les deux côtés voient la même information, au même moment.

CE QUI EST PENSÉ POUR LE SÉNÉGAL

• Les montants en FCFA, les dates au format d'ici.
• Les paiements par Wave, Orange Money et carte bancaire.
• Les relances par WhatsApp, pour atteindre un locataire là où il lit ses messages.
• L'application fonctionne en français, intégralement.

VOS DONNÉES

Un propriétaire ne voit que ses biens et ses locataires ; un locataire ne voit que son logement. La connexion peut être protégée par une double authentification, et les appareils connectés à votre compte sont consultables et révocables à tout moment.
```

---

## 2. Informations sur l'app

| Champ | Valeur |
|---|---|
| Catégorie principale | **Entreprise** |
| Catégorie secondaire | **Finance** |
| Droits d'auteur | `2026 [raison sociale]` — **à compléter** |
| Nom pour l'App Store | TerangaLoc |

> La catégorie « Immobilier » n'existe pas sur l'App Store. « Entreprise »
> est celle des outils de gestion professionnelle ; c'est là que se rangent
> les concurrents.

---

## 3. Classification par âge

Toutes les questions du questionnaire : **Aucun / Non**. L'application ne
contient ni violence, ni contenu sexuel, ni alcool, ni jeux d'argent, ni
contenu généré par les utilisateurs rendu public.

Deux questions récentes, signalées par Apple sur ta page :

- **Partage de position** → **Non**. Vérifié : l'application ne demande
  aucune permission de localisation, et le manifeste Android fusionné n'en
  contient aucune.
- **Rencontres** → **Non**.

Une question mérite réflexion : **« échanges non modérés entre
utilisateurs »**. La messagerie propriétaire ↔ locataire existe, mais elle
est fermée (chacun ne parle qu'aux personnes de son bail), pas publique.
Réponse honnête : oui, il y a une messagerie ; non, ce n'est pas un réseau
social ouvert. Cela donne en général 4+.

---

## 4. Confidentialité de l'app

**URL de la politique de confidentialité** : indispensable, et elle n'existe
pas encore. Le texte est prêt dans `PRIVACY_POLICY.md` à la racine du dépôt,
avec ses passages entre crochets à compléter. Il faut le publier à une
adresse publique (par exemple `terangaloc.sn/confidentialite`) et coller
l'URL ici.

Réponses au questionnaire « Collecte de données », établies en lisant le
code et non en les supposant :

| Donnée | Collectée | Usage | Liée à l'identité | Suivi |
|---|---|---|---|---|
| Nom | Oui | Fonctionnalité de l'app | Oui | Non |
| Adresse e-mail | Oui | Fonctionnalité, identification | Oui | Non |
| Numéro de téléphone | Oui | Fonctionnalité, relances | Oui | Non |
| Photos | Oui | Fonctionnalité (travaux, états des lieux, justificatifs) | Oui | Non |
| Identifiant utilisateur | Oui | Fonctionnalité, diagnostics | Oui | Non |
| Identifiant d'appareil | Oui | Fonctionnalité (notifications push) | Oui | Non |
| Données de diagnostic / plantages | Oui | Diagnostics | Oui | Non |
| Informations financières | **Non** | — | — | — |
| Position | **Non** | — | — | — |
| Contacts | **Non** | — | — | — |
| Publicité | **Non** | — | — | — |

Points d'attention :

- **« Informations financières » : non.** L'application n'enregistre aucun
  numéro de carte ni code secret : elle ouvre la page de l'opérateur, qui
  encaisse. Seules la référence de transaction et son résultat reviennent.
- **« Suivi » (App Tracking Transparency) : non**, pour toutes les lignes.
  Aucune donnée n'est partagée avec un courtier ni croisée avec d'autres
  applications. Donc aucune demande ATT à afficher.
- **Les données de plantage sont liées à l'identité** : Crashlytics reçoit
  l'identifiant interne du compte (`suivreUtilisateur`). C'est volontaire —
  sans lui, une erreur n'est rattachée à personne. Il faut le déclarer.

---

## 5. Vérification de l'app (App Review Information)

| Champ | À remplir par toi |
|---|---|
| Prénom, nom, téléphone, e-mail | tes coordonnées |
| **Compte de démonstration** | **obligatoire** — identifiant et mot de passe d'un compte propriétaire contenant de vraies données de test |
| Notes | voir le modèle ci-dessous |

Le compte de démonstration n'est pas optionnel : l'écran de connexion est la
première chose qu'un examinateur voit, et sans identifiants il rejette la
version en « Guideline 2.1 — Information Needed », ce qui coûte un
aller-retour d'une semaine. Le compte doit contenir des immeubles, des baux
et des quittances : un compte vide montre des écrans vides.

Modèle de notes :

```
TerangaLoc est un outil de gestion locative destiné aux propriétaires
bailleurs au Sénégal, et à leurs locataires.

L'application comporte deux espaces distincts :
— propriétaire : biens, baux, loyers, quittances, dépenses, travaux ;
— locataire : son logement, son loyer, ses quittances, ses demandes.

Le compte de démonstration fourni est un compte propriétaire. Pour voir
l'espace locataire, se connecter avec : [second compte].

L'application est intégralement en français, sa clientèle étant
sénégalaise. Les montants sont en francs CFA.
```

---

## 6. Captures d'écran — ce qu'il faut produire

Apple exige au minimum le format **6,7 pouces (1290 × 2796)**. Les autres
tailles en sont dérivées automatiquement. Entre 3 et 10 images.

Les six écrans qui racontent l'application, dans l'ordre :

1. **Tableau de bord propriétaire** — les chiffres du mois, l'essentiel en un
   coup d'œil.
2. **Liste des biens** — immeubles et appartements avec leurs photos.
3. **Détail d'un bail** — loyer, charges, caution, échéances.
4. **Encaissement et quittance** — le geste quotidien.
5. **Espace locataire** — son loyer et ce qu'il reste à payer.
6. **Incident signalé** — photos à l'appui.

Il faut un compte avec de vraies données pour que ces écrans ne soient pas
vides. Les captures se prennent sur un simulateur iPhone 17 Pro Max, qui
donne exactement 1290 × 2796.

---

## 7. Ce qui bloque la soumission, par ordre d'importance

1. **Aucun build sur App Store Connect.** À archiver depuis Xcode et
   téléverser. Avant cela : vérifier l'équipe de signature (`DR54MH4Z4J`) et
   cocher « Push Notifications » sur l'App ID.
2. **Les captures d'écran** — rien n'existe, voir § 6.
3. **L'URL de confidentialité** — voir § 4.
4. **Le compte de démonstration** — voir § 5.
5. **Le paiement de l'abonnement** — voir ci-dessous. C'est le point qui
   peut coûter le plus de temps.

---

## 8. Le risque de rejet qui n'est pas dans les champs

`abonnement_page.dart:135` ouvre la page de paiement de l'opérateur avec
`LaunchMode.externalApplication`, et l'abonnement conditionne l'usage de
l'application : sans lui, l'espace propriétaire passe en lecture seule (402).

C'est exactement la situation que vise la **règle 3.1.1 de l'App Store** :
un service numérique consommé dans l'application doit passer par l'achat
intégré d'Apple, qui prélève sa commission. Un bouton qui renvoie vers Wave
ou PayDunya pour débloquer des fonctions de l'app est la cause de rejet la
plus courante pour ce type de produit.

Trois issues, à choisir avant de soumettre plutôt qu'après un rejet :

- **L'exception « services d'entreprise » (3.1.3(e))** : l'application est
  vendue à des professionnels, pas à des particuliers. C'est défendable pour
  une régie ou un bailleur professionnel, beaucoup moins pour le
  propriétaire de deux appartements. À argumenter dans les notes de
  vérification.
- **L'exception « service multiplateforme » (3.1.3(b))** : l'abonnement est
  souscrit sur le site web, et l'application se contente de reconnaître un
  compte déjà actif. Condition stricte : **aucun lien ni incitation à
  l'achat dans l'application iOS**. Il faudrait masquer le bouton de
  paiement sur iOS — `Platform.isIOS` dans `abonnement_page.dart` — et
  afficher seulement l'état de l'abonnement.
- **L'achat intégré Apple** : conforme sans discussion, mais 15 à 30 % de
  commission, et un travail de développement à part entière.

SaamBiz ne dit rien de ce risque : chez elle `Env.paiementSimule` vaut
`true`, aucun argent ne circule dans l'application, donc Apple n'a jamais eu
à trancher.
