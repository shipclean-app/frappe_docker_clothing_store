# Catalogue et variantes

Ce document fixe la structure catalogue minimum pour eviter les erreurs de stock et de caisse.

## Modele recommande

### 1. Utiliser un article modele par produit

Chaque produit vendable doit partir d'un `Item Template`:

- exemple modele: `ROB-ALBA`
- nom: `Robe Alba`
- groupe d'article: `Robes`
- marque: optionnelle

### 2. Utiliser des variantes pour les tailles et couleurs

Attributs retenus en v1:

- `Taille`
- `Couleur`

Chaque combinaison utile devient une variante:

- `ROB-ALBA-NOI-S`
- `ROB-ALBA-NOI-M`
- `ROB-ALBA-BLE-M`

Ne pas creer de variantes qui ne seront jamais achetees ni vendues.

## Regle SKU

Format recommande:

```text
FAMILLE-MODELE-COULEUR-TAILLE
```

Exemples:

- `TSH-LEA-BLA-S`
- `PNT-MILA-BEI-38`
- `ROB-ALBA-NOI-M`

## Regles de nommage

- `FAMILLE`: code court stable (`TSH`, `ROB`, `PNT`, `VST`)
- `MODELE`: code stable du modele (`ALBA`, `MILA`, `LEA`)
- `COULEUR`: code court (`NOI`, `BLA`, `BEI`, `VER`)
- `TAILLE`: valeur courte (`XS`, `S`, `M`, `L`, `36`, `38`)

Ne pas utiliser:

- des espaces
- des accents
- des noms libres saisis a chaque fois
- des SKU differents pour une meme logique

## Code-barres

Recommandation v1:

- `1 code-barres par variante`

Pourquoi:

- un scan doit pointer vers une variante unique
- evite les erreurs de taille/couleur
- simplifie le POS et l'inventaire

Si la boutique n'utilise pas encore de scan, garder quand meme le champ disponible pour la phase suivante.

## Champs article autorises en phase 1

### Obligatoires

- `Item Code` pour le `SKU`
- `Item Name`
- `Item Group`
- `Stock UOM`
- `Has Variants` pour le modele
- `Item Attributes` pour `Taille` et `Couleur`
- `Standard Selling Rate` ou `Item Price`

### Optionnels mais utiles

- `Brand`
- image article

### Custom fields autorises

- `Saison`
- `Collection`

Ne pas ajouter d'autres champs sans raison quotidienne concrete.

## Proprietaire des donnees

Une seule personne doit etre responsable de:

- creation des articles modeles
- creation des variantes
- verification des SKU
- verification des code-barres
- archivage des articles inactifs

Si plusieurs personnes modifient librement le catalogue, la base se degradera vite.

## Regle de creation article

1. Creer le modele.
2. Verifier le groupe d'article.
3. Definir `Taille` et `Couleur` si le produit varie.
4. Generer uniquement les variantes utiles.
5. Attribuer un code-barres unique par variante.
6. Verifier le prix de vente.
7. Verifier l'etat stockable.

## Regle de stock

### Entrepots

Par defaut:

- `Boutique`

Option acceptable si une reserve physique existe:

- `Boutique`
- `Reserve`

Ne pas ajouter d'autres entrepots en phase 1.

### Seuils de stock bas

Les alertes doivent etre pensees au niveau le plus utile pour l'achat:

- si la boutique vend vraiment par variante, regler le stock bas sur les variantes critiques
- sinon rester simple et surveiller les articles les plus vendus

## Donnees de demo minimales pour valider le setup

Avant go-live, preparer au moins:

- 3 familles d'articles
- 5 modeles
- 10 a 20 variantes
- 2 fournisseurs
- 2 modes de paiement
- 1 stock initial realiste

Sans jeu de donnees proche du reel, la recette POS ne vaut pas grand-chose.

