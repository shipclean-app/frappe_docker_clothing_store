# Customisations et deploiement

Ce document fixe comment rendre les customisations rejouables et deployables sur une machine Linux locale.

Pour l'execution quotidienne, utiliser prioritairement `./bootstrap` et suivre `guide_de_travail.md`.

## Contexte actuel

Dans l'etat actuel du projet:

- le repo d'infra est `frappe_docker_clothing_store`
- l'app custom est dans `https://github.com/tleguede-works/boutique_custom`
- la branche utilisee pour l'app custom est `develop`
- `apps.json` pointe deja vers ce repo
- l'image de travail est `custom:16`
- le site de travail est `boutique.local`

Ce document decrit donc le workflow cible, mais aussi le workflow deja valide sur cet environnement.

## Principe de base

Ce qui est critique ne doit pas vivre seulement dans la base.

La source de verite doit etre:

- le standard ERPNext
- ou une app `boutique_custom` versionnee dans Git

## Customisations low-code retenues

En phase 1, seules ces categories sont autorisees:

- `Custom Field`
- `Property Setter` si necessaire
- `Print Format`
- `Report` simple

Tout le reste passe en phase 2.

## Objets a exporter dans `boutique_custom`

### Custom fields

Uniquement si utilises:

- `Item-saison`
- `Item-collection`

### Print formats

- `Boutique POS Ticket`
- `Boutique Item Label`

### Reports

- `Boutique Stock Bas`
- `Boutique Ventes Du Jour`
- `Boutique Ventes Par Article`
- `Boutique Ventes Par Paiement`
- `Boutique Stock Par Variante`

### Property setters

A n'utiliser que si une vraie simplification POS ou article le justifie.

## Regle de travail

1. Faire la customisation dans l'interface ERPNext.
2. Declarer les fixtures filtrees dans `hooks.py`.
3. Exporter les fixtures depuis le site de dev.
4. Committer dans Git.
5. Rejouer sur un environnement de test propre.
6. Deployer seulement apres verification.

Regle pratique:

- le repo `frappe_docker_clothing_store` porte l'infra, le script `bootstrap` et la documentation
- le repo `boutique_custom` porte la structure de l'app et les fixtures exportees

## Fichiers fournis

- `apps.json.example`: exemple d'image custom avec ERPNext et `boutique_custom`
- `custom.env.example`: base d'env locale pour une machine Linux
- `boutique_custom_template/`: squelette de depart pour le depot de l'app

## Workflow de build recommande

1. Verifier que le repo `boutique_custom` existe et que la branche `develop` est poussee.
2. Verifier que `apps.json` pointe vers ce repo.
3. Lancer `./bootstrap init` si besoin.
4. Verifier `custom.env`.
5. Construire l'image custom avec `./bootstrap build`.

Si le depot est prive:

- laisser `apps.json` avec une URL GitHub propre
- ne pas y ecrire le token
- `./bootstrap build` injectera temporairement `GH_TOKEN` ou `GITHUB_TOKEN` pour les URLs `github.com` sans credentials

Si le depot est public, rien de special n'est necessaire.

### Cas particulier Codespaces / GitHub CLI

Dans Codespaces, le `GITHUB_TOKEN` injecte par l'environnement peut prendre la main sur `gh`.

Pour les commandes `gh` sensibles, faire:

```bash
unset GITHUB_TOKEN GH_TOKEN
gh auth status
```

Sinon tu peux avoir de faux problemes de permission.

### Ce que fait `./bootstrap build`

Le script:

- resout `apps.json`
- injecte temporairement le token GitHub si necessaire
- invalide le cache non seulement sur le contenu de `apps.json`, mais aussi sur le HEAD distant des branches declarees

Commande equivalente simplifiee:

```bash
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --build-arg=CACHE_BUST="<fingerprint apps + branches distantes>" \
  --secret=id=apps_json,src=apps.json \
  --tag=custom:16 \
  --file=images/layered/Containerfile .
```

## Workflow de deploiement Linux local

1. Copier `custom.env.example` en `custom.env` via `./bootstrap init`.
2. Adapter le mot de passe DB et le nom du site.
3. Activer `CUSTOM_IMAGE`, `CUSTOM_TAG` et `PULL_POLICY=missing` dans `custom.env` quand l'image custom existe.
4. Generer le compose rendu avec `./bootstrap render`.
5. Demarrer la stack avec `./bootstrap start`.
6. Laisser les migrations se faire.
7. Creer ou restaurer le site.
8. Verifier les fixtures.

Dans l'etat actuel, `custom.env` est deja configure pour utiliser `custom:16`.

### Si des residues d'anciens essais perturbent la stack

Si tu observes:

- mot de passe MariaDB incoherent
- ancien site partiellement casse
- containers relances mais etat applicatif incoherent

alors il faut repartir proprement:

```bash
./bootstrap wipe --yes
./bootstrap start
```

Puis recreer le site ou restaurer proprement une sauvegarde.

### Creation du site

En environnement neuf:

```bash
./bootstrap site-create boutique.local admin
./bootstrap site-install-app boutique.local boutique_custom
./bootstrap migrate boutique.local
```

Si le site `boutique.local` existe deja:

```bash
./bootstrap site-install-app boutique.local boutique_custom
./bootstrap migrate boutique.local
```

### Si la migration echoue avec `bench_migrate.lock`

Ce verrou peut apparaitre si le service `migrator` est encore en train de finir son travail.

Dans ce cas:

1. attendre quelques secondes
2. relancer simplement:

```bash
./bootstrap migrate boutique.local
```

## Controle avant livraison

Avant de livrer, verifier:

- l'app `boutique_custom` est dans l'image
- les fixtures sont rejouees
- les champs `Saison` et `Collection` existent si retenus
- les rapports attendus existent
- le ticket POS est present
- la recette terrain est validee

Verification rapide utile:

```bash
./bootstrap exec bash -lc 'bench --site boutique.local list-apps'
```

## Backup et reprise

La sauvegarde minimum acceptable est:

```bash
./bootstrap backup all
```

Conserver:

- les backups de base
- les fichiers publics et prives
- le depot Git a jour de `boutique_custom`
- le `custom.env` utilise en production

## Test de redeploiement a blanc

Ce test n'est pas optionnel.

Faire au moins une fois:

1. nouveau site ou environnement propre
2. image reconstruite depuis Git
3. demarrage de la stack
4. verification des fixtures
5. verification d'un backup/restauration

Si ce test n'a jamais ete passe, le deploiement n'est pas fiable.

## Etat valide sur cet environnement

Ce qui a deja ete confirme ici:

- le repo `boutique_custom` existe et est pousse sur `develop`
- `apps.json` pointe vers ce repo
- l'image `custom:16` se construit
- la stack demarre sur cette image
- `boutique.local` existe
- `boutique_custom` est installable sur le site

Autrement dit, le blocage principal n'est plus l'infrastructure ni GitHub. La suite normale est la configuration ERPNext et l'export progressif des fixtures.

