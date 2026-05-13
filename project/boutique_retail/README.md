# Boutique Retail Kit

Ce dossier transforme le cadrage en livrables directement utilisables pour une v1 ERPNext de boutique de pret-a-porter.

## Ce que ce kit fixe

- un perimetre phase 1 ferme
- des decisions par defaut pour ne pas bloquer le projet
- une structure catalogue/variantes exploitable
- une recette terrain minimale avant go-live
- une methode propre pour versionner et redeployer les customisations

## Ordre d'utilisation

1. Lire `guide_de_travail.md` et suivre l'ordre de travail.
2. Lire ce fichier et valider les decisions par defaut.
3. Configurer le catalogue avec `catalogue_et_variantes.md`.
4. Faire la recette avec `recette_terrain.md`.
5. Preparer l'app `boutique_custom` et le deploiement avec `customisations_et_deploiement.md`.

## Decisions par defaut recommandees

Ces choix sont les valeurs par defaut de la v1. Ne les changer que s'il y a une raison metier claire.

| Sujet | Recommandation v1 | Pourquoi |
| --- | --- | --- |
| Entrepots | `1 entrepot` par defaut | Le plus simple a tenir. Passer a `Boutique + Reserve` seulement s'il existe une reserve physique separee et un vrai besoin de transfert. |
| Code-barres | `1 code-barres par variante` | Evite les erreurs de taille/couleur au scan. |
| Client par defaut | `Walk-in Customer` | Le POS reste rapide. Les fiches clients nominatives restent facultatives. |
| Fidelite | `Non en phase 1` | Ajoute de la complexite pour peu de valeur au demarrage. |
| Retours | `Oui, retour simple standard seulement` | Il faut couvrir le besoin courant sans lancer un projet d'echange complexe. |
| Echanges | `Non en phase 1` | A traiter plus tard si le retour standard est insuffisant. |
| Prix de vente | `TTC cote boutique` | Plus naturel pour une vente au detail. La fiscalite reste geree par ERPNext. |
| Paiements POS | `Especes` et `Carte` | Suffisant pour un demarrage. Ajouter d'autres modes seulement s'ils sont utilises tous les jours. |
| Structure SKU | `Famille-Modele-Couleur-Taille` | Lisible, stable et exploitable en stock comme au POS. |
| Creation catalogue | `Une seule personne responsable` | Evite les variantes incoherentes et les doublons. |

## Perimetre phase 1 retenu

### Standard ERPNext assume

- articles et variantes
- listes de prix
- stock et alertes de stock bas
- achats fournisseurs
- POS
- paiements
- taxes
- clients
- rapports standard utiles

### Customisations autorisees

- convention de `SKU`
- attributs `Taille` et `Couleur`
- champs custom `Saison` et `Collection` seulement si vraiment utilises
- ticket POS lisible
- etiquette article simple si la boutique en a besoin
- rapports sauvegardes: `stock bas`, `ventes du jour`, `ventes par article`, `ventes par mode de paiement`, `stock par variante` si necessaire
- roles minimaux et acces POS epures

### Hors perimetre assume

- promotions avancees
- fidelite avancee
- commissions vendeurs
- echanges avec parcours optimise
- dashboards merchandising
- logique Python/JS metier
- nouveaux DocTypes
- integration TPE/PSP

## Livrables de ce dossier

- `catalogue_et_variantes.md`: structure produit, regles SKU, ownership et saisie minimale
- `guide_de_travail.md`: procedure pas-a-pas avec le script `./bootstrap`
- `recette_terrain.md`: scenarii de validation avant go-live
- `customisations_et_deploiement.md`: fixtures, app custom, build image, backup et redeploiement
- `boutique_custom_template/`: squelette minimal pour lancer le depot de l'app custom

## Regle non negociable

Une customisation critique ne doit jamais exister seulement dans la base du site.

La source de verite doit etre:

- soit le standard ERPNext
- soit l'app `boutique_custom` versionnee dans Git

