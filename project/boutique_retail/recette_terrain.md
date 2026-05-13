# Recette terrain

Ce document liste les flux minimum a valider avant toute mise en service.

## Regle de validation

Chaque flux doit etre teste:

- de bout en bout
- avec des donnees proches du reel
- par la personne qui utilisera vraiment le systeme si possible

Si un flux critique bloque ou genere trop de clics, le projet n'est pas pret.

## Flux a tester

### 1. Creation d'un article modele avec variantes

But:

- verifier la logique `SKU`
- verifier `Taille` et `Couleur`
- verifier les prix et le code-barres

Attendu:

- les variantes sont creees sans doublon
- les SKU sont coherents
- les variantes sont trouvables facilement

### 2. Vente POS avec scan

But:

- verifier le parcours le plus rapide

Attendu:

- le code-barres ouvre la bonne variante
- le prix remonte correctement
- le paiement `Especes` et `Carte` fonctionne
- le ticket sort correctement

### 3. Vente POS sans scan

But:

- verifier le cas degrade

Attendu:

- la vendeuse retrouve l'article rapidement
- la taille/couleur reste lisible
- le panier peut etre finalise sans confusion

### 4. Vente avec taille/couleur

But:

- verifier que la selection des variantes est exploitable

Attendu:

- la bonne variante est ajoutee au panier
- le stock baisse sur la bonne variante

### 5. Retour simple

But:

- verifier que le besoin courant est couvert sans workflow complexe

Attendu:

- le retour peut etre rattache a la vente ou saisi proprement
- le stock est corrige
- le paiement ou l'avoir suit la regle definie

### 6. Cloture de caisse

But:

- verifier la fin de journee

Attendu:

- le total systeme correspond au reel ou l'ecart est visible
- les modes de paiement sont lisibles
- la cloture est faisable sans intervention technique

### 7. Reception fournisseur

But:

- verifier le flux achat vers stock

Attendu:

- la reception alimente le bon entrepot
- le cout remonte correctement
- les variantes receptionnees sont exactes

### 8. Ajustement de stock

But:

- verifier qu'un ecart d'inventaire simple peut etre corrige

Attendu:

- l'ajustement modifie le stock attendu
- le mouvement reste tracable

## Fiche de recette a remplir

Pour chaque flux, noter:

- `date`
- `testeur`
- `jeu de donnees utilise`
- `resultat: OK / KO`
- `blocage rencontre`
- `decision: corriger maintenant / repousser`

## Criteres de go-live

Le go-live peut etre envisage seulement si:

- les ventes POS passent avec et sans scan
- le retour simple est compris et accepte
- la cloture de caisse est faisable par l'utilisateur final
- la reception fournisseur et l'ajustement stock passent sans ambiguite
- aucune confusion majeure n'apparait sur les variantes

