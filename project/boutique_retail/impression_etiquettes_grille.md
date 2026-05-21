# Impression étiquettes en grille (PDF)

ERPNext **ne propose pas nativement** une planche A4 avec plusieurs articles en grille (image + nom + code-barres). Le kit boutique ajoute ce flux via `boutique_custom`.

## Prérequis

- Variantes avec **code-barres** (remplissage auto à l’enregistrement, ou `autofill_barcodes`).
- Dépendance Python dans le bench :

```bash
./bootstrap build
./bootstrap restart
./bootstrap link-assets
```

(`link-assets` lie les JS sur le conteneur **frontend** et installe `python-barcode` sur le **backend**.)

## Utilisation (recommandé)

1. **[MENU]** **Stock** → **Article** (liste).
2. Cocher les **variantes** à étiqueter (pas les modèles « A des variantes »).
3. Bouton **Etiquettes grille PDF** (barre d’outils de la liste).
4. Le navigateur télécharge `etiquettes-articles.pdf`.

Chaque case du PDF contient :

- **Image** article (si renseignée sur la fiche),
- **Nom** article,
- **Code-barres CODE128** scannable + texte du code.

## Paramètres

| Paramètre | Défaut | Description |
|-----------|--------|-------------|
| `columns` | 3 | Colonnes sur la page A4 (1 à 5) |

Appel API manuel :

```bash
./bootstrap exec bash -lc 'bench --site boutique.local execute \
  "boutique_custom.print.item_label_sheet.download" \
  --kwargs "{\"items\": [\"ROB-ALBA-M-Noir\"], \"columns\": 3}"'
```

## Ce que ERPNext standard fait (sans custom)

| Action | Résultat |
|--------|----------|
| Liste → **Imprimer** + format Article | Souvent **une page par article**, pas une grille |
| Format d’impression Jinja seul | Un document = un `doc` Article |

La grille multi-articles nécessite un **template HTML dédié** + génération PDF (implémenté ici).

## Dépannage

| Problème | Cause / solution |
|----------|------------------|
| Bouton absent | `./bootstrap build` → `restart` → `link-assets` après MAJ `boutique_custom` |
| « Aucune variante avec code-barres » | Ouvrir la variante → **Codes-barres** vide → réenregistrer ou `autofill_barcodes` |
| Modèle parent coché | Ignoré volontairement — cocher les **variantes** |
| Scan échoue | Vérifier que l’étiquette imprimée encode la **même** valeur que **Codes-barres** |
| `python-barcode` manquant | `bench pip install python-barcode` |
| `only_for() takes ... 3 were given` | Mettre à jour `boutique_custom` (Frappe 16 : `only_for((rôles,))` en tuple) |

## Fichiers techniques

- `boutique_custom/print/item_label_sheet.py`
- `boutique_custom/templates/print_formats/boutique_item_label_sheet.html`
- `boutique_custom/public/js/item_list_labels.js`
