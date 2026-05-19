# Parcours : reset, wizard, config boutique et traductions

Ce document décrit la **chaîne de commandes** pour repartir sur un site neuf (wizard ERPNext), appliquer la configuration boutique automatique, puis compléter les traductions françaises.

Variables par défaut : site `boutique.local`, port `8080`, mot de passe admin `admin`.

Référence : combos **C** (reset), **K** (catalogue test), **L** (traductions) dans [`guide_de_travail.md`](guide_de_travail.md).

---

## Commande unique (workflows)

Le parcours complet peut s’exécuter via le moteur de workflows Bootstrap (pauses wizard / taxes / relecture CSV, vérifications entre étapes) :

```bash
# Reset intégral + wizard + config + traductions (demande confirmation wipe)
./bootstrap workflow run reset-config --yes

# Variantes utiles
./bootstrap workflow run reset-config --yes --skip-backup
./bootstrap workflow run reset-config --yes --skip-translations    # sans phase traductions
./bootstrap workflow run reset-config --yes --with-catalog
./bootstrap workflow run reset-config --yes --until wizard         # s’arrête après le wizard

# Après une pause (wizard, taxes, CSV) : reprendre
./bootstrap workflow resume

# Site déjà créé, uniquement post-wizard + traductions
./bootstrap workflow run post-wizard-setup --site boutique.local

# Nouveau Codespace (clone neuf, sans wipe)
./bootstrap workflow run codespace-init --yes

# Traductions seules (combo L)
./bootstrap workflow run translation --site boutique.local \
  --translation-csv project/boutique_retail/reports/translation-p0-reviewed.csv

# Aperçu sans exécuter les commandes
./bootstrap workflow run reset-config --dry-run

# Lister / détailler les scénarios
./bootstrap workflow list
./bootstrap workflow describe reset-config
```

Fichiers YAML : `project/boutique_retail/workflows/`. Moteur : `bootstrap.d/lib/`. État et logs : `.bootstrap/workflow-state.json`, `.bootstrap/workflow.log`.

Le détail manuel ci-dessous reste valide pour le dépannage ou les étapes isolées.

---

## 0. Prérequis — image Docker à jour

Si vous venez de mettre à jour le dépôt `boutique_custom`, reconstruire l’image pour inclure `setup-boutique` et les fixtures :

```bash
./bootstrap build
./bootstrap restart
```

Sans cette étape, après un `wipe`, l’ancienne image peut ne pas contenir les nouveaux scripts.

---

## 1. Reset complet → setup wizard (combo C)

**Attention :** `wipe --yes` supprime la base de données et le site. `custom.env` et `apps.json` sont conservés.

```bash
cd /chemin/vers/frappe_docker_clothing_store

# Optionnel mais recommandé
./bootstrap backup boutique.local

./bootstrap wipe --yes
./bootstrap start

# Attendre que la stack soit prête
./bootstrap status

./bootstrap site-create boutique.local admin
./bootstrap site-install-app boutique.local boutique_custom
./bootstrap migrate boutique.local
```

`site-create` utilise automatiquement l'utilisateur MariaDB **`root`** et le mot de passe **`DB_PASSWORD`** de `custom.env` (sans invite interactive). Ne pas confondre avec le mot de passe admin ERPNext (`admin` dans la commande ci-dessus).

Si `migrate` échoue avec un verrou (`bench_migrate.lock`), attendre 10 secondes puis relancer :

```bash
./bootstrap migrate boutique.local
```

### Wizard dans le navigateur

1. Ouvrir **http://localhost:8080**
2. Le **setup wizard** ERPNext doit s’afficher (`setup_complete = 0` sur site neuf)
3. Choisir **Français** dès que possible
4. Renseigner le **vrai nom de société** (pas un nom démo)
5. Pays **France**, devise **EUR**, plan comptable adapté (ex. SYSCOHADA)
6. **Ne pas cocher** « données de démonstration »
7. Terminer le wizard : **un seul onglet**, pas de double clic (évite les deadlocks)

---

## 2. Configuration boutique automatique (après wizard)

```bash
./bootstrap setup-boutique boutique.local
```

### Options utiles

| Option | Effet |
|--------|--------|
| `--dry-run` | Affiche ce qui serait fait, sans écrire en base |
| `--with-catalog` | Crée attributs Taille/Couleur, modèle test, stock initial |
| `--force` | Met à jour les enregistrements déjà présents |
| `--company "Ma Société"` | Société cible (sinon société par défaut du site) |
| `--warehouse Boutique` | Nom de l’entrepôt (défaut : `Boutique`) |

Exemples :

```bash
./bootstrap setup-boutique boutique.local --dry-run
./bootstrap setup-boutique boutique.local --with-catalog
```

### Ce que fait `setup-boutique`

- Langue système **fr**
- Correctif comptes stock **SYSCOHADA** (si applicable)
- Entrepôt **Boutique**
- Modes de paiement **Espèces** et **Carte**
- Client **Walk-in Customer**
- **POS Profile** lié à l’entrepôt et aux paiements

### Checklist taxes (manuel — avant test POS)

Le script ne configure pas la TVA (trop dépendant du régime fiscal).

1. **Comptabilité** → modèle de **taxes de vente** (TVA France)
2. Lier le modèle au **Profil point de vente** (`Boutique`)
3. Faire une **vente test** : la TVA sur le ticket doit être correcte

### Ouvrir la caisse

- Menu : **Ventes → POS → POS**
- URL directe : http://localhost:8080/app/point-of-sale

Puis enchaîner avec [`recette_terrain.md`](recette_terrain.md).

---

## 3. Traductions françaises (combo L)

Ordre recommandé : **après** `setup-boutique` et un premier passage dans le Desk/POS (pour repérer les libellés encore en anglais).

### Étape 1 — Audit des textes manquants

```bash
./bootstrap translation-audit --priority retail
```

Le rapport est écrit dans :

`project/boutique_retail/reports/translation-gaps-retail-fr.csv`

Filtres `retail` = priorités P0 + P1 + P2 (modules vente, stock, POS, achats, setup, Desk).

Autres priorités :

```bash
./bootstrap translation-audit --priority P0
./bootstrap translation-audit --priority all
```

### Étape 2 — Relecture du CSV

1. Ouvrir `translation-gaps-retail-fr.csv`
2. Remplir la colonne **`translated_text`** (ou créer un fichier dédié, ex. `translation-p0-reviewed.csv`)
3. S’appuyer sur [`glossaire_traduction_fr.md`](glossaire_traduction_fr.md) pour la cohérence des termes

Fichier d’exemple fourni :

`project/boutique_retail/reports/translation-p0-reviewed.sample.csv`

### Étape 3 — Import sur le site

```bash
./bootstrap translation-import boutique.local project/boutique_retail/reports/translation-p0-reviewed.csv
```

Remplacer le chemin par **votre** CSV relu.

### Étape 4 — Rafraîchir l’interface

- Navigateur : **Ctrl+F5**
- Ou :

```bash
./bootstrap exec bash -lc 'bench --site boutique.local clear-cache'
```

### Étape 5 — Exporter les fixtures (prochains resets)

Pour que les traductions soient rejouées après `wipe` + `install-app boutique_custom` :

```bash
./bootstrap export-fixtures boutique.local
```

Puis committer les fichiers générés dans le dépôt **`boutique_custom`** (`fixtures/translation.json`).

Si le code fixtures a changé :

```bash
./bootstrap build
./bootstrap restart
```

---

## Récapitulatif — une page

```text
[Automatique — recommandé]
  ./bootstrap workflow run reset-config --yes

[Manuel — équivalent]
[Prérequis]
  ./bootstrap build && ./bootstrap restart   # si boutique_custom a changé

[Reset + wizard]
  ./bootstrap backup boutique.local          # optionnel
  ./bootstrap wipe --yes
  ./bootstrap start
  ./bootstrap site-create boutique.local admin
  ./bootstrap site-install-app boutique.local boutique_custom
  ./bootstrap migrate boutique.local
  → Navigateur : wizard FR, France, SANS démo

[Config boutique]
  ./bootstrap setup-boutique boutique.local
  → Taxes manuel + recette_terrain.md
  → http://localhost:8080/app/point-of-sale

[Traductions]
  ./bootstrap translation-audit --priority retail
  → Relecture CSV + glossaire_traduction_fr.md
  ./bootstrap translation-import boutique.local <votre-csv-revu.csv>
  ./bootstrap export-fixtures boutique.local
```

---

## Rappels

| Commande | Effet sur les données |
|----------|------------------------|
| `./bootstrap clean` | Supprime les conteneurs, **garde** les volumes |
| `./bootstrap wipe --yes` | Supprime conteneurs **et** volumes (DB + site) |
| Réinstall seule | **N’améliore pas** le taux de traduction UI (les `.po` sont dans l’image) |

Les surcharges françaises passent par le DocType **`Translation`** exporté dans **`boutique_custom`**, pas par modification directe des fichiers `fr.po` dans le conteneur.
