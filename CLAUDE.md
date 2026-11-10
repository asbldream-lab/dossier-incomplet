# Dossier Incomplet — jeu Godot 4.5

Jeu satirique : obtenir ses papiers en préfecture. Chaque niveau = une étape administrative.
Chaque niveau : phase action temps réel (monstres-fournitures) → boss en combat tour par tour
façon Expedition 33 (menu d'attaques + parade en temps réel). Noms d'attaques drôles, mais
**chaque attaque est un vrai coup animé** (l'attaquant court vers la cible, frappe, la cible encaisse, il revient).

## Règles de travail (économie de tokens)
- Avancer par petites étapes ; l'utilisateur teste dans Godot et décrit le problème en une phrase.
- Pas de captures d'écran ni de lecture de gros logs sauf nécessité ; ne lire que les fichiers concernés.
- Contenu (stats, attaques, textes, boss) dans `data/combat.json`, pas dans le code.
- Réutiliser `battle.gd` pour tous les boss (ajouter un boss = une entrée dans `bosses`).

## Architecture (scènes construites en code, .tscn minimales)
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
`... --headless --path . --quit-after 600 res://scenes/battle.tscn` (erreurs dans la sortie).

## Git / GitHub
Repo privé : https://github.com/asbldream-lab/dossier-incomplet (branche `main`).
Workflow : une petite étape = un commit clair en français, puis `git push`. Fichiers `.godot/` ignorés.
Repo public. Version jouable : https://asbldream-lab.github.io/dossier-incomplet/ — republier après chaque étape avec `./tools/deploy_web.sh`
(export web, renderer Compatibility, branche `gh-pages`).
