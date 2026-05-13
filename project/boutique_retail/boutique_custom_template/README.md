# boutique_custom template

Ce dossier est un point de depart minimal pour le depot Git de l'app custom.

## Usage recommande

1. Creer un depot separe `boutique_custom`.
2. Copier ce dossier dans ce depot.
3. Remplacer le metadata de `pyproject.toml` et `hooks.py`.
4. Installer l'app dans le bench de dev.
5. Exporter les fixtures depuis le site.

## Ce que ce template couvre

- metadata minimale de l'app
- fichier `hooks.py`
- declaration de fixtures filtrees
- dossier `fixtures/` pret a recevoir les exports

## Ce que ce template ne couvre pas

- logique metier Python
- JS custom
- nouveaux DocTypes
- scripts de migration complexes

Si un besoin demande ces elements, il ne fait plus partie de la phase 1.

