# Dossier Incomplet — jeu Godot 4.5

Jeu satirique : obtenir ses papiers en préfecture. Chaque niveau = une étape administrative.
RPG 2D : chaque niveau = salle d'attente (exploration, PNJ) puis boss au guichet en combat façon Pokémon.
Tout (mots, objets, règles) doit faire ressentir la difficulté d'obtenir ses papiers.

## Règles de travail (économie de tokens)
- Avancer par petites étapes ; l'utilisateur teste dans Godot et décrit le problème en une phrase.
- Pas de captures d'écran ni de lecture de gros logs sauf nécessité ; ne lire que les fichiers concernés.
- Contenu (chiffres, attaques, textes) dans `data/rpg2d.json`, pas dans le code.

## VERSION 2D (principale)
- `scripts/game.gd` — autoload `Game` : inputs, état de la partie (`has_ticket, called, clock, talked, inv, skipped, checkpoint`), `data2d` (JSON).
- **Salle d'attente** `scenes/explore.tscn` (`scripts/2d/explore.gd`) : décor `assets/2d/salle.svg` (généré par `tools/boss/room.py`),
  persos `assets/2d/chars/*.svg` (générés par `tools/boss/chars.py`). Prendre un ticket (847), parler aux 3 PNJ (chacun donne un objet et
  fait avancer l'horloge), le 847 est sauté → réclamer à la porte du Bureau 3 → combat.
- **Combat** `scenes/battle2d.tscn` (`scripts/2d/battle2d.gd`), tout est dans la clé `battle` du JSON :
  - Jauge DOSSIER (35 % → 100 % = victoire), PATIENCE (0 = on craque), horloge (12h00 = guichet fermé). Chaque action coûte des minutes.
  - Menu en bas à droite : ATTAQUE (`moves`), DÉFENSE (`defenses` : rester poli / garder le dossier en main), OBJETS (`items`), FUIR.
  - Elle : attaques du `pool`, exigences (`demands` → statuts STYLO BLEU / PIÈCE MANQUANTE / TIMBRE EXIGÉ, soignés par les objets des PNJ),
    coups annoncés un tour avant (`tampon` aux tours `stamp_turns`, `egare` une fois) à parer avec DÉFENSE.
  - Fins `texts.end` : win / crack / closed / flee ; « Retenter le guichet » recharge le combat depuis `Game.checkpoint`.
- `scripts/2d/fx.gd` (helpers, shader grain/vignette), `scripts/2d/dialogue.gd` (boîte de texte de l'exploration).
- Tests (lancer en arrière-plan avec sortie dans un fichier ; `load()` et non `preload` du script de combat dans un script `-s`) :
  - `godot --headless -s tools/test_explore.gd` : joue toute la salle d'attente jusqu'au combat.
  - `godot --headless -s tools/test_battle.gd -- 300` : équilibrage (prudent ≈ 70 % de victoires, hasard ≈ 12 %, spam d'une attaque 0 %).
  - `godot -s tools/test_battle_ui.gd -- /dossier` : partie complète au clavier simulé + captures (vraie fenêtre).
  - `godot -s tools/test_battle_ends.gd -- /dossier` : défaites, boutons de fin, fuite à la souris (vraie fenêtre).

## Architecture version 3D (ancienne, gardée de côté)
- `scripts/game.gd` — autoload `Game` : inputs (touches physiques, ZQSD en AZERTY), librairie d'animations
  fusionnée UAL1+UAL2, chargement JSON, helpers (box, label3d, float_text, build_room, ui_label, ui_bar), changements de scène.
- `scripts/character_model.gd` — `CharacterModel` : mannequin GLB + AnimationPlayer partagé. `play`, `play_once` (retourne la durée), `idle`, `attach(bone)`.
  `Game.MODEL_YAW` = PI (modèles tournés vers -Z). Mettre 0 si les persos sont de dos.
- `scripts/player.gd` — joueur temps réel (bouger, combo épée J/clic, roulade Espace, PV).
- `scripts/monster.gd` — monstres : agrafeuse, classeur, dossier, tampon (meshes primitives, attaque télégraphiée jaune).
- `scripts/level1.gd` + `scenes/level1.tscn` — salle d'attente de la préfecture, puis intro boss → `Game.go_battle("secretaire")`.
- `scripts/battle.gd` + `scenes/battle.tscn` — combat tour par tour. PA (points d'action), parade (Espace pendant le « ! »),
  parer tous les coups = contre-attaque, phase 2 à 50 % PV, effets `ap_drain`, `stun`, `knockback`, `ranged`.
- `scripts/hud.gd` — HUD temps réel.

## Assets
- `assets/characters/UAL1_Standard.glb`, `UAL2_Standard.glb` (animations, Quaternius CC0), `Mannequin_F.glb` (secrétaire, même rig).
- Joueur = mannequin homme (UAL1). Animations utiles : Sword_Regular_A/B/C, Sword_Regular_Combo, Sword_Heavy_Combo,
  Sword_Block, Sword_Dash, Melee_Hook, Punch_Jab/Cross, Roll, Hit_Chest, Hit_Knockback, Death01, OverhandThrow,
  Spell_Simple_Shoot, Consume, Idle_FoldArms, Idle_No, Sprint, Jog_Fwd, Dance (Godot retire le suffixe _Loop à l import).
- Timings des coups : `hits` = fractions de la durée de l'animation (à ajuster dans le JSON si ça tombe à côté).

## Niveaux
1. Accueil de la préfecture — boss : Mme Bertrand, agent d'accueil. ✅ v1
2+. À définir avec l'utilisateur.

## Vérif rapide sans éditeur
`~/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . --import` puis
les tests ci-dessus (erreurs dans la sortie).

## Git / GitHub
Repo public : https://github.com/asbldream-lab/dossier-incomplet (branche `main`).
Workflow : une petite étape = un commit clair en français, puis `git push`. Fichiers `.godot/` ignorés.
Version jouable : https://asbldream-lab.github.io/dossier-incomplet/ — republier après chaque étape avec `./tools/deploy_web.sh`
(export web, renderer Compatibility, branche `gh-pages`).

## Portrait du boss (redessiné)
- Généré par `python3 tools/boss/build.py` (kit.py = traits encrés tremblés, hachures, lettrage ; bg/body/head/desk/arms/fx = une partie chacun) → `assets/2d/secretaire.svg`, puis `python3 -I tools/split_portrait.py assets/2d/secretaire.svg` pour les calques.
- Aperçu fidèle au rendu Godot : `godot --headless -s tools/render_svg.gd -- in.svg out.png` (pas de filtres ni de `<text>` : le rasteriseur ne les gère pas).
