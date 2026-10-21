# Mitte Fehde — update 2

Mitteralteriche Fehde, an offline Godot PC board-game prototype.

## Run on Windows

1. Extract the whole Windows ZIP into a new writable folder (such as Documents).
2. Open **MitteFehde**, then double-click **Play.cmd**.
3. Choose solo or 2–4 local players, click **Start new campaign**, and confirm.

The portable Godot 4.5 Windows x64 runtime is included. No installation or internet is needed. This package runs the editable source through the bundled engine; it is not a signed release export.

**Start a new campaign for this update.** Version 1 saves are not compatible with the changed deck, combat state and trail ownership. The previous project and downloads were preserved. Version 2 saves restore committed armies, pending movement, deck/discard and random-number state.

## What's changed

- The title is **Mitte Fehde** throughout the updated game and package.
- Your exact 28-card list: 9 Surplus, 9 Famine, 10 March. One copy of each listed card; discards reshuffle when exhausted.
- March moves forward or backward 2–6 spaces, including through the six-lot routes.
- Attackers choose a fixed force before the first battle round. They cannot add troops during the fight. Retreat returns surviving attackers; victory stations them on the captured lot.
- Both sides automatically roll min(3, troops in the fight) dice. There is no dice-count selector. All corresponding sorted dice pairs resolve; ties still favor the defender.
- **No +1 defense bonus**, including for complete divisions.
- Four former trails are now six-lot divisions: 54 ownable lots altogether. Each lot costs 60 G; markets cost 120 G and produce 40 G; barracks cost 100 G and produce 6 T. Complete divisions double building output only.
- Simple central dice, building and two-color battle animations. Each action remains visible for 1.3–1.8 seconds before the next action can begin. Opponents use the same pacing. Menu/Rules pause play.
- Serif titles, burgundy and brass accents, pointed arches, steep spires and a rose window add a modest German Gothic character without external art assets.

## Playing

Follow **Roll & march → resolve lot → station/build → cards → End turn**. Highest initiative roll starts, so an AI house may move first. In solo mode you control green House Alder. Local players share the mouse.

On a defended rival lot, choose the number of troops using the spinner, then **Commit attacking force**. Each **Fight next round** uses mandatory dice counts for both sides. You can retreat between rounds. The center shows both house colors and the actual dice results. Uncommitted reserve troops stay out of the battle.

Click any lot to inspect its full name, division and owner. Smaller six-lot panels show lot numbers, price/garrison, buildings and pawns; action buttons always apply to your pawn's current location. Trail routes remain connected at the same entrances and exits. On backward movement you may enter a trail from its opposite end.

Save/Load handles the manual save. Each action autosaves; Menu → Resume autosave restores it. The launcher stores saves under `saves/Godot/app_userdata/Mitte Fehde — Mitteralteriche Fehde/`. A new campaign replaces the autosave but preserves the manual save.

## Rules and assumptions

Read **RULES.txt**, also available through the in-game Rules button. This update assumes you may commit any number from 1 through your entire reserve, all surviving attackers occupy a captured lot, and retreat returns survivors to reserve. These complete the new fixed-force system. Backward movement follows reversed road connections with route choice at a branch, rather than retracing a recorded travel history. Six-lot pricing follows the table proposed before you authorized this update.

Victory remains 16 lots or last survivor. Markets, barracks, atomic payment/check rules and once-per-turn income retain their established behavior. There is still no audio, online multiplayer or Steam integration. AI and balance are rough; the larger board may change match length.

## Editing and testing

Double-click **Open editor.cmd**, or import `project.godot` in your own Godot 4.5 editor and press F5. The source-only ZIP needs your own Godot installation and does not contain launcher/runtime files.

- `game.gd`: deterministic rules, deck, movement, committed combat, AI, saving.
- `board.gd`: procedural board, Gothic illustration and lightweight animations.
- `main.gd` / `main.tscn`: controls, timing and menus.
- `tests.gd`: rules regression suite and 20 AI campaigns.
- `ui_tests.gd`: real UI callbacks, timing checks and rendered animation images.

Run **Run tests.cmd** for the rules suite. Developers can run `runtime/Godot_console.exe --path . --script ui_tests.gd` for UI checks; screenshots go in the project's parent folder. See **TEST-REPORT.md**.

Official runtime: https://godotengine.org/download/archive/4.5-stable/
Engine license and third-party notices are included in runtime/. No new external assets or dependencies.
