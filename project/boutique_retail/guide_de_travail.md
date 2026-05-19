# Guide de travail ERPNext

Ce guide est le mode d'emploi principal du projet.

Objectif:

- ne pas improviser les commandes
- ne pas oublier l'ordre des etapes
- separer clairement ce qui se fait au terminal et ce qui se fait dans l'interface ERPNext

Le point d'entree unique est le script:

```bash
./bootstrap
```

## 1. Vue d'ensemble

Le travail se fait en 6 phases:

1. nettoyage initial
2. preparation des fichiers locaux
3. preparation de l'app `boutique_custom`
4. build et demarrage ERPNext
5. customisations dans l'interface ERPNext
6. export, sauvegarde et preparation du deploiement local

## Contexte actuel du projet

Au moment ou ce guide est mis a jour:

- le repo d'infra est `frappe_docker_clothing_store`
- l'app custom est dans `https://github.com/tleguede-works/boutique_custom`
- la branche de travail de `boutique_custom` est `develop`
- `apps.json` pointe deja vers ce repo
- le site de travail vise est `boutique.local`

Ne change ces valeurs que si tu veux volontairement repartir sur une autre structure.

## 2. Commandes disponibles

Les commandes utiles sont:

```bash
./bootstrap help
./bootstrap init
./bootstrap start
./bootstrap stop
./bootstrap restart
./bootstrap status
./bootstrap logs
./bootstrap clean
./bootstrap wipe --yes
./bootstrap build
./bootstrap site-create <site>
./bootstrap site-install-app <site> <app>
./bootstrap export-fixtures <site>
./bootstrap backup [site|all]
./bootstrap migrate [site|all]
./bootstrap setup-boutique <site> [--with-catalog] [--dry-run] [--force]
./bootstrap translation-audit [--priority retail]
./bootstrap translation-import <site> <csv>
./bootstrap shell
./bootstrap exec <commande...>

# Workflows (parcours automatises — voir project/boutique_retail/workflows/)
./bootstrap workflow list
./bootstrap workflow run <name> [--yes] [--site ...] [--dry-run]
./bootstrap workflow resume
```

## 2 bis. Parcours bootstrap par cas d'usage

Chaque parcours est un **combo** de commandes dans l'ordre. Variables par defaut : site `boutique.local`, port `8080`, admin `admin`.

| ID | Cas | Quand | Workflow (recommande) | Combo terminal manuel | UI ERPNext |
|----|-----|-------|----------------------|----------------------|------------|
| A | Premiere installation | Clone neuf | `workflow run codespace-init` | `init` → … → `migrate` | Wizard → `setup-boutique` |
| B | Journee de travail | Stack prete | — | `start` → travail → `stop` | Desk / POS |
| C | Reset complet | Repartir a zero | `workflow run reset-config --yes` | `backup`? → `wipe` → … | Wizard → `setup-boutique` |
| D | Redemarrage stack | Crash / `.env` | `restart` ou `stop` + `start` | — |
| E | Site existant | Volumes OK | `start` → `migrate` si besoin | Reprendre config |
| F | MAJ app custom | Nouveau commit `boutique_custom` | `build` → `restart` → `site-install-app` → `migrate` | Verifier ecrans |
| G | Export customisations | Lot UI valide | `export-fixtures` → commit `boutique_custom` → `build` → `restart` | — |
| H | Sauvegarde | Avant reset | `backup boutique.local` | — |
| I | Depannage | Erreur migrate | `status` → `logs backend` → `migrate` → `restart` | — |
| K | Catalogue test rapide | Apres wizard | `setup-boutique <site> --with-catalog` | `/app/point-of-sale` |
| L | Traductions boutique | FR retail | `workflow run translation` | `translation-audit` → … → `export-fixtures` | Desk FR |
| W | Post-wizard seul | Site deja cree | `workflow run post-wizard-setup` | `setup-boutique` → taxes → POS | Desk / POS |

`clean` supprime les conteneurs **sans** les volumes. `wipe --yes` supprime **aussi** la base et le site.

### Combo C — Reset complet

**Efface :** volumes Docker (DB + site). **Conserve :** `custom.env`, `apps.json`, image locale.

```bash
./bootstrap backup boutique.local
./bootstrap wipe --yes
./bootstrap start
./bootstrap site-create boutique.local admin
./bootstrap site-install-app boutique.local boutique_custom
./bootstrap migrate boutique.local
```

Puis navigateur : wizard (FR, France, **sans** donnees demo) → `./bootstrap setup-boutique boutique.local` → checklist taxes → [`recette_terrain.md`](recette_terrain.md).

### Checklist taxes (post-wizard, manuel)

Le workflow `pause_taxes` affiche les URLs ERPNext (liste / nouveau modele / profil POS Boutique). Voir aussi [`parcours_reset_config_traduction.md`](parcours_reset_config_traduction.md).

1. Modele de taxes de vente (TVA).
2. Lier au **POS Profile** `Boutique`.
3. Vente test : TVA correcte sur le ticket.

### Combo L — Traductions

```bash
./bootstrap translation-audit --priority retail
# Revoir project/boutique_retail/reports/translation-gaps-retail-fr.csv
# Completer translated_text (voir glossaire_traduction_fr.md)
./bootstrap translation-import boutique.local project/boutique_retail/reports/translation-p0-reviewed.csv
./bootstrap export-fixtures boutique.local
```

## 3. Phase 0 - nettoyage initial

Tu as deja lance ERPNext sur ce clone. Il faut donc repartir proprement.

### A faire

1. Verifier l'etat:

```bash
./bootstrap status
```

2. Arreter et supprimer les conteneurs du projet:

```bash
./bootstrap clean
```

3. Si tu veux un reset complet sans conserver les donnees Docker:

```bash
./bootstrap wipe --yes
```

### Regle

- `clean` supprime les conteneurs et le reseau du projet, mais garde les volumes
- `wipe --yes` supprime aussi les volumes et efface les donnees locales Docker de cette stack

Utiliser `wipe --yes` seulement si tu veux vraiment repartir de zero.

## 4. Phase 1 - preparation locale

### A faire au terminal

1. Initialiser les fichiers locaux:

```bash
./bootstrap init
```

Cela cree:

- `custom.env`
- `apps.json`

### Fichiers a verifier ensuite

#### `custom.env`

Au minimum:

- `DB_PASSWORD`
- `FRAPPE_SITE_NAME_HEADER`
- `HTTP_PUBLISH_PORT`

Par defaut, `custom.env.example` ne force pas l'image custom. C'est volontaire.

#### `apps.json`

Ce fichier doit contenir:

- ERPNext
- ton depot Git `boutique_custom`

Tant que `apps.json` pointe vers l'URL exemple, `./bootstrap build` ne doit pas etre lance.

Dans l'etat actuel, le fichier attendu est:

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-16"
  },
  {
    "url": "https://github.com/tleguede-works/boutique_custom",
    "branch": "develop"
  }
]
```

Si `boutique_custom` est prive sur GitHub:

- garder une URL GitHub normale dans `apps.json`
- ne pas y stocker le token
- `./bootstrap build` injectera temporairement `GH_TOKEN` ou `GITHUB_TOKEN` si l'un des deux est present

### Cas particulier Codespaces / GitHub CLI

Dans Codespaces, `gh` peut utiliser un `GITHUB_TOKEN` injecte par l'environnement a la place de ton vrai login GitHub.

Pour toutes les operations `gh` sensibles (`repo create`, `repo view`, `auth setup-git`, etc.), utiliser de preference:

```bash
unset GITHUB_TOKEN GH_TOKEN
gh auth status
```

Si tu oublies cette etape, tu peux avoir des erreurs de permission trompeuses alors que ton compte GitHub est bien connecte.

## 5. Phase 2 - preparation de l'app custom

### A faire au terminal

Dans l'etat actuel, le depot existe deja:

- repo local: `/workspaces/boutique_custom`
- repo distant: `https://github.com/tleguede-works/boutique_custom`
- branche: `develop`

Si tu repars de zero plus tard, il faut:

1. Creer un vrai depot Git `boutique_custom`.
2. Copier dans ce depot le contenu de:

```text
project/boutique_retail/boutique_custom_template/
```

3. Remplacer dans le template:

- `Your Name`
- `you@example.com`
- les noms et metadata utiles

4. Pousser le depot sur GitHub ou ton remote Git.
5. Mettre a jour `apps.json` avec la vraie URL.

### Regle de travail pour ce repo

Tout ce qui touche aux customisations phase 1 doit finir ici:

- fixtures exportees
- metadata de l'app
- correctifs de structure si Frappe demande un module supplementaire

Ne pas committer ces changements dans le repo `frappe_docker_clothing_store`.

### Pourquoi cette phase doit venir tot

Si tu fais des customisations UI avant que `boutique_custom` soit installee sur le site, tu risques de travailler sans pipeline propre d'export de fixtures.

## 6. Phase 3 - build et demarrage ERPNext

### Cas A - tu veux juste redemarrer ERPNext standard

```bash
./bootstrap start
```

### Cas B - tu veux travailler proprement avec l'app custom

1. Construire l'image:

```bash
./bootstrap build
```

Le build peut etre long. C'est normal.

Le script:

- resout `apps.json`
- gere le token GitHub si necessaire
- invalide le cache aussi quand la branche distante d'une app a change

Si `boutique_custom` est prive, verifier que `gh auth status` fonctionne ou qu'un `GH_TOKEN` / `GITHUB_TOKEN` est disponible dans l'environnement avant de lancer le build.

2. Activer l'image custom dans `custom.env` en renseignant:

```text
CUSTOM_IMAGE=custom
CUSTOM_TAG=16
PULL_POLICY=missing
```

Dans l'etat actuel, ces lignes sont deja actives dans `custom.env`.

3. Demarrer:

```bash
./bootstrap start
```

4. Verifier:

```bash
./bootstrap status
```

5. Suivre les logs si besoin:

```bash
./bootstrap logs
./bootstrap logs backend
```

## 7. Phase 4 - creation du site

### A faire au terminal

### Cas A - environnement neuf

1. Creer le site:

```bash
./bootstrap site-create boutique.local admin
```

2. Si l'image contient l'app custom, l'installer sur le site:

```bash
./bootstrap site-install-app boutique.local boutique_custom
```

3. Si besoin, lancer une migration:

```bash
./bootstrap migrate boutique.local
```

### Cas B - le site existe deja

Verifier d'abord:

```bash
./bootstrap exec bash -lc 'find sites -mindepth 2 -maxdepth 2 -name site_config.json | sed "s#/site_config.json##"'
```

Si `sites/boutique.local` existe deja:

- ne pas recreer le site
- lancer seulement:

```bash
./bootstrap site-install-app boutique.local boutique_custom
./bootstrap migrate boutique.local
```

### Si tu as garde d'anciens volumes Docker

Si la base ou les volumes viennent d'un ancien essai, tu peux tomber sur:

- mot de passe MariaDB incoherent
- anciens sites partiellement casses
- etats de stack difficiles a comprendre

Dans ce cas, la bonne solution est de repartir proprement:

```bash
./bootstrap wipe --yes
./bootstrap start
./bootstrap site-create boutique.local admin
./bootstrap site-install-app boutique.local boutique_custom
```

## 8. Phase 5 - ce qui se fait dans l'interface ERPNext

Une fois le site accessible, les actions suivantes se font dans l'interface ERPNext.

### A faire dans ERPNext

#### Parametrage standard

Apres le wizard ERPNext :

```bash
./bootstrap setup-boutique boutique.local
# optionnel : --with-catalog pour article test
```

Puis manuellement :

- taxes (checklist section 2 bis)
- roles de base si besoin

Le script couvre : langue FR, comptes stock SYSCOHADA, entrepot `Boutique`, modes de paiement, client Walk-in, POS Profile.

#### Catalogue et variantes

- creer les attributs `Taille` et `Couleur`
- creer les articles modeles
- generer les variantes utiles
- verifier la logique `SKU`
- renseigner les code-barres si scan utilise

#### Customisations low-code

- ajouter `Saison` et `Collection` seulement si retenus
- creer le ticket POS lisible
- creer l'etiquette article si necessaire
- creer les rapports retenus

### Ce qui ne se fait pas en phase 1

- scripts Python/JS metier
- nouveaux DocTypes
- promotions complexes
- fidelite avancee
- echanges optimises

## 9. Phase 6 - ce qui se fait au terminal apres les customisations UI

Des qu'un lot de customisations UI est termine:

1. Exporter les fixtures:

```bash
./bootstrap export-fixtures boutique.local
```

2. Verifier les fichiers exportes dans le depot `boutique_custom`.
3. Committer et pousser ce depot.
4. Rebuild l'image si necessaire:

```bash
./bootstrap build
```

5. Redemarrer:

```bash
./bootstrap restart
```

### Si la migration echoue avec un verrou temporaire

Tu peux voir une erreur du type `bench_migrate.lock`.

Ce n'est pas forcement grave: le service `migrator` peut etre en train de finir son propre passage.

Dans ce cas:

1. attendre quelques secondes
2. relancer simplement:

```bash
./bootstrap migrate boutique.local
```

Si l'app est deja installee, tu peux verifier rapidement avec:

```bash
./bootstrap exec bash -lc 'bench --site boutique.local list-apps'
```

## 10. Recette terrain

Avant tout deploiement final, valider les flux de:

- creation article modele
- vente avec scan
- vente sans scan
- vente avec variantes
- retour simple
- cloture de caisse
- reception fournisseur
- ajustement de stock

Reference detaillee:

```text
project/boutique_retail/recette_terrain.md
```

## 11. Sauvegarde

### Sauvegarde manuelle

```bash
./bootstrap backup all
```

Ou pour un site:

```bash
./bootstrap backup boutique.local
```

Toujours conserver:

- la sauvegarde ERPNext avec fichiers
- le depot Git `boutique_custom`
- `custom.env`
- `apps.json`

## 12. Preparation de la machine finale Linux

Quand la v1 est stable:

1. recuperer le repo `frappe_docker`
2. recuperer `boutique_custom`
3. copier `custom.env`
4. copier `apps.json`
5. lancer:

```bash
./bootstrap build
./bootstrap start
```

6. creer ou restaurer le site
7. verifier que les fixtures et les rapports sont bien presents
8. tester un backup/restauration a blanc

## 13. Ordre de travail recommande

Si tu veux la version la plus simple possible, suis exactement cet ordre:

1. `./bootstrap clean`
2. `./bootstrap init`
3. verifier que `apps.json` pointe bien vers `tleguede-works/boutique_custom` sur `develop`
4. verifier que le repo `/workspaces/boutique_custom` est a jour
5. `./bootstrap build`
6. verifier que `CUSTOM_IMAGE`, `CUSTOM_TAG` et `PULL_POLICY=missing` sont actifs dans `custom.env`
7. `./bootstrap start`
8. si besoin, `./bootstrap site-create boutique.local admin`
9. `./bootstrap site-install-app boutique.local boutique_custom`
10. `./bootstrap migrate boutique.local`
11. faire le parametrage standard dans ERPNext
12. faire les customisations UI retenues
13. `./bootstrap export-fixtures boutique.local`
14. commit/push `boutique_custom`
15. `./bootstrap build`
16. `./bootstrap restart`
17. `./bootstrap backup boutique.local`
18. faire la recette terrain

## 14. Regle pratique finale

Si tu hesites entre une action interface et une action terminal:

- `interface ERPNext` pour configurer et personnaliser le fonctionnel
- `terminal via ./bootstrap` pour demarrer, arreter, sauvegarder, exporter, reconstruire et deployer

