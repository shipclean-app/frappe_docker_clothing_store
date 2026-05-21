# Script démo Loom — ERPNext boutique (10 min, version cliente)

**Pour qui :** propriétaire / gérante boutique (ex. **Celia Handmade**) — pas une démo « logiciel », une démo **quotidien magasin**.

**Cadence :** 70–80 mots/min → **~700 mots** à l’oral (cible **≤ 10 min**).

**Config démo :** société **Celia Handmade** · entrepôt **Boutique** · caisse **Boutique** · client **Client de passage** · paiements **Espèces** / **Carte**.

---

## Avant d’enregistrer (obligatoire)

- [ ] **2 ventes déjà passées** en caisse (sinon les rapports sont vides → perd l’impact).
- [ ] Articles avec **vrais noms** (ex. « Robe lin Mia », pas « Test Item ») et **prix crédibles**.
- [ ] Caisse **ouverte** : **Ventes** → **Ouverture de caisse** (profil **Boutique**).
- [ ] Variantes **Taille** / **Couleur** + au moins un **code-barres** de test.
- [ ] Phrase d’ouverture prête : *« J’ai paramétré l’écran comme si c’était déjà votre boutique. »*
- [ ] Zoom navigateur **110–125 %**, plein écran, onglets parasites fermés.

---

## Ce qu’elle doit retenir (vos 3 messages)

1. **Vendeuse** : encaisse vite, bonne taille / couleur, scan ou pas.
2. **Vous** : la journée en un écran — sans refaire Excel le soir.
3. **Stock** : quand ça part en caisse, la bonne variante baisse toute seule.

---

## 0:00 – 1:00 | Accroche — son problème, pas ERPNext

**[ÉCRAN :]** connexion → **Accueil**

> Bonjour. En dix minutes, je ne vous montre pas « un ERP » : je vous montre **votre boutique en action**.  
> Le sujet, c’est simple : quand votre vendeuse vend une robe **taille M, bleu**, le stock **M bleu** baisse tout seul — et vous, le soir, vous voyez **la journée** — espèces, carte, ce qui s’est vendu — **sans tableur**.  
> J’ai configuré ça pour **Celia Handmade**. On commence par ce que fait la vendeuse toute la journée : **la caisse**.

*(~72 mots)*

---

## 1:00 – 5:30 | La caisse — scène principale (~4 min 30)

**[MENU :]** **Ventes** → **Point de vente**  
*(URL : `/app/point-of-sale`)*

**[Si message « caisse fermée » :]**

**[MENU :]** **Ventes** → **Ouverture de caisse** → **+ Ajouter** → profil **Boutique** → **Soumettre** → retour **Point de vente**

> Voici l’écran du quotidien : la **caisse**. Déjà prêt pour vous — profil **Boutique**, **Espèces**, **Carte**, et **Client de passage** pour ne pas perdre du temps à chaque vente.

### Vente 1 — avec scan (~1 min 30)

**[ACTION :]** Scanner (ou saisir) le code-barres d’une robe → elle arrive dans le panier, **bon prix, bonne taille**.

> Là, ce n’est pas « une robe » vague : c’est **la bonne variante**. Pas de risque d’encaisser un M à la place d’un L.

**[ACTION :]** Ajouter un 2ᵉ article (liste ou recherche).

**[ACTION :]** **Encaissement** → **Espèces** ou **Carte** → **Finaliser la commande**.

> En quelques clics : ticket, paiement enregistré. **Personne ne ressaisit rien** dans un fichier à part.

### Vente 2 — sans scan (~1 min)

**[ACTION :]** Recherche « Robe… » → fenêtre **taille** + **couleur** → **Ajouter au panier** → même **Encaissement**.

> Quand l’étiquette est illisible ou qu’il n’y a pas de scan : la vendeuse **voit** couleur et taille avant de valider. Même rapidité, moins d’erreurs en rayon.

### Preuve stock (~45 s)

**[MENU :]** **Stock** → **Article** → ouvrir la robe vendue → onglet **Variantes de l’article** *(ou colonne **Stock réel**)*

**[ACTION :]** Montrer que **M bleu** (ou la variante vendue) a bien **baissé d’une unité**.

> C’est le point que les boutiques adorent : **la caisse et le stock parlent ensemble**. Pas de « je crois qu’il en reste 2 » le lendemain.

*(~220 mots)*

---

## 5:30 – 7:30 | Vos chiffres — fin de journée sans Excel (~2 min)

**[MENU :]** Barre de recherche → **Boutique Ventes Du Jour** → Entrée

> Maintenant, **votre** écran : pas celui de la vendeuse.

**[ACTION :]** **Boutique Ventes Du Jour** — chiffre du jour en quelques secondes.

> C’est ce que vous regardez après la fermeture : **combien aujourd’hui**, sans recopier les tickets.

**[MENU :]** Recherche → **Boutique Ventes Par Paiement**

**[ACTION :]** Montrer **Espèces** vs **Carte**.

> Vous voyez tout de suite la part cash / carte — utile pour la caisse réelle et la banque.

**[MENU :]** Recherche → **Boutique Stock Bas**

**[ACTION :]** Lignes articles sous le seuil.

> Avant la rupture en rayon : **quoi réapprovisionner**. Les ventes POS alimentent tout ça — **aucune double saisie**.

*(~115 mots)*

---

## 7:30 – 9:00 | Nouvelle collection — tailles et couleurs (~1 min 30)

**[MENU :]** **Stock** → **Article** → ouvrir **Robe lin Mia** *(déjà créée — ne pas créer live sauf si elle le demande)*

**[ACTION :]** Onglet **Variantes de l’article** : S, M, L × couleurs, stock par ligne.

> Quand vous recevez une collection : une robe existe en **plusieurs tailles et couleurs**. Chaque ligne a son stock et son code-barres. En caisse, **on ne confond pas les tailles**.

**[OPTION — si elle demande « comment on ajoute un modèle » :]**

**[MENU :]** **Stock** → **Article** → **+ Ajouter** → cocher **A des variantes** → **Taille**, **Couleur** → **Enregistrer** *(30 s max, sans détail technique)*

> On peut paramétrer les nouveaux modèles ensemble ; aujourd’hui je vous montre surtout **l’usage magasin**, pas la saisie bureau.

*(~95 mots)*

---

## 9:00 – 10:00 | Clôture + suite pour elle (~1 min)

**[MENU :]** **Ventes** → **Clôture de caisse** → ouvrir la clôture du jour *(aperçu, pas besoin de valider)*

> En fin de journée : **Clôture de caisse** — totaux, historique.  
> Pour résumer : votre vendeuse encaisse **sans se tromper de taille** ; vous pilotez **sans Excel** ; le stock suit **la vraie variante vendue**.  
> Prochaines étapes possibles pour vous : formation vendeuse une demi-journée, étiquettes, retours — on choisit ensemble ce qui est prioritaire. Merci, vos questions sont les bienvenues.

*(~75 mots)*

---

## Fiche prompteur — chemins menu (pour vous, pas à dire à l’oral)

| Minute | À faire | Chemin / URL |
|--------|---------|----------------|
| 0:00 | Connexion | **Accueil** `/app/home` |
| 1:00 | Caisse | **Ventes** → **Point de vente** `/app/point-of-sale` |
| 1:00 | Ouvrir caisse si besoin | **Ventes** → **Ouverture de caisse** |
| 4:30 | Preuve stock | **Stock** → **Article** → variante vendue |
| 5:30 | Jour | Recherche **Boutique Ventes Du Jour** |
| 6:15 | Paiements | **Boutique Ventes Par Paiement** |
| 6:45 | Réassort | **Boutique Stock Bas** |
| 7:30 | Collection | **Stock** → **Article** → **Variantes de l’article** |
| 9:00 | Clôture | **Ventes** → **Clôture de caisse** `/app/pos-closing-entry` |

---

## Mots à éviter à l’oral / mots à privilégier

| Éviter | Dire plutôt |
|--------|-------------|
| ERP, DocType, SKU, soumettre | caisse, fiche article, référence, valider |
| Traçabilité, workflow | tout est enregistré, historique |
| Module Stock / Selling | **Stock**, **Ventes** |
| Import, fixture | déjà configuré pour vous |

---

## Plans de secours

| Situation | Action |
|-----------|--------|
| **&lt; 8 min** demandées | Couper « nouvelle collection » ; garder caisse + 2 rapports. |
| **&gt; 10 min** | Ne pas développer entrée de stock / achats ; renvoyer en accompagnement. |
| Rapports vides | Faire 1 vente live avant les rapports (30 s). |
| Libellé en anglais | **Ctrl+F5** ; continuer en expliquant la fonction. |

---

## Timing & volume oral

| Bloc | Durée | Mots ~ |
|------|-------|--------|
| Accroche | 1:00 | 72 |
| Caisse + preuve stock | 4:30 | 220 |
| Rapports | 2:00 | 115 |
| Collection (court) | 1:30 | 95 |
| Clôture | 1:00 | 75 |
| **Total** | **~10:00** | **~577** + transitions |

Marge à 70 m/min : ~8 min 15 de texte pur → **~1 min 45** pour clics et silences naturels → **confortable dans 10 min**.

---

## Conseils Loom

1. Parler à **« vous »** (la gérante), pas « l’utilisateur ».
2. Montrer **ses** produits, **ses** prix — jamais des données génériques.
3. Après chaque vente POS : une phrase **bénéfice** (« le stock M bleu a bougé »).
4. Ne pas s’excuser pour l’interface : « on configure une fois, ensuite c’est simple ».
5. Finir par une **question ouverte** : *« Qu’est-ce qui vous rassurerait pour un pilote en magasin ? »*
