# Mitt Fued — outer-ring update

Open **Play.cmd** in this project folder to play, or open project.godot in Godot. Start a new campaign for this board.

## Board
The original rebuilding artwork is preserved. All 24 inner lots, trail connections, and route-choice prompts are removed. The outer hitboxes stay in the same places.

| Side, clockwise from its starting corner | First division | Second division |
| --- | --- | --- |
| Top, from Muster | Guildmarket: 2 lots | Sunspire: 6 lots |
| Right, from Levy | Tidewatch: 3 lots | Red Keep: 4 lots |
| Bottom, from Treasury | Riverhold: 2 lots | Rose Quarter: 6 lots |
| Left, from Tax | Unicorn Vale: 3 lots | Lion's Reach: 4 lots |

30 ownable lots, eight divisions, and four unchanged corners. Original outer lot names and positions are retained. The game/window/menu/art title is Mitt Fued.

## Economy (unchanged)
| Division size | Lot cost | Market cost | Market EoT | Barracks cost | Barracks EoT |
| --- | --- | --- | --- | --- | --- |
| 2 | 20 G | 15 G | 5 G | 20 G | 2 T |
| 3 | 30 G | 30 G | 10 G | 40 G | 3 T |
| 4 | 40 G | 60 G | 20 G | 60 G | 4 T |
| 6 | 60 G | 120 G | 40 G | 100 G | 6 T |

Full divisions double building output only. Base income remains 20 G + 2 T per own turn, and each bare lot gives 1 T without doubling. Build on owned land while passing or at your destination, at most once per movement.

Cards, chosen troop commitments, mandatory dice, survivor-only retreat, atomic payments, persistent checks, four players, and the 16-lot/last-survivor victory remain unchanged. See RULES.txt, also accessible in game.

## Saves
Save format is now version 3. Start fresh: older maps have incompatible lot counts and division membership. Manual and automatic saves now use campaign-ring.save and autosave-ring.save. With Play.cmd, the new title stores them under saves/Godot/app_userdata/Mitt Fued/. Existing old-title saves are preserved.

## Art and editing
board.gd uses the unchanged art/gothic-background.png and draws the 34 outer tiles and new title over it. This avoids the old image's baked-in inner frames.
art/render-board.gd exports new MittFued PNGs and art/hitboxes.json from the actual current geometry. Old MitteFehde PNGs remain as historical assets and are not loaded by the game.

- game.gd: rules, movement, economy, AI, saves.
- board.gd: artwork, outer geometry, labels and animations.
- main.gd: UI and actions.
- tests.gd: rule regressions plus 20 full seeded AI campaigns.
- ui_tests.gd: UI callbacks, title/geometry checks and animation rendering.

Run **Run tests.cmd** for rule checks. UI tests: runtime/Godot_console.exe --path . --script ui_tests.gd. They write MittFued screenshots in this project folder.
The included runtime tested here is Godot 4.5 stable. No new dependencies or online features.
