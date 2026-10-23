# Mitte Fehde Gothic board artwork

The PNGs match the current v2 project's 58 hitboxes: 54 lots plus four corner spaces. Frames are rendered from `board.gd`'s actual `layout_board()` rectangles, not guessed by the image generator. The four inner divisions retain their six-lot, two-row arrangement and serpentine ordering.

## Files

- `MitteFehde-board.png`: labelled preview / board with fixed lot names.
- `MitteFehde-board-unlabelled.png`: recommended integration asset; the game can draw its existing lot names and changing values over this. Division headings and central title remain in the artwork.
- `MitteFehde-alignment-proof.png`: the same board with exact hitbox outlines and indexes in cyan for checking alignment.
- `hitboxes.json`: all 58 rectangles in logical board coordinates.
- `gothic-background.png`: generated decorative artwork before the exact game layout was rendered over it.
- `render-board.gd`: Godot renderer used to create the final board PNGs.
- `art-prompt.txt`: prompt for the background, created with the built-in image-generation tool. Final borders/text were rendered deterministically in Godot 4.5.

## Size and placement

Each finished board PNG is **1740 x 1488 pixels**. Draw it at board-local position **(0, 0)** with size **870 x 744**. Do not auto-stretch it to fill a differently proportioned Control. A hitbox at `(x, y, width, height)` maps to `(2x, 2y, 2width, 2height)` in the PNG.

The existing board Control has a minimum height of 740 while its background extends to 744; the lowest hitbox ends at 729. The art uses the full background height without moving any hitboxes.

## Integration notes

This is an art delivery; the playable project has not been changed. Merely adding a background node underneath the existing drawing will not show the artwork: the current opaque background and lot fills would cover it.

To integrate, copy the unlabelled PNG into the Godot project and draw it first inside the existing board's `_draw()`:

```gdscript
# At script scope, after copying the PNG into res://art/:
var board_art = preload("res://art/MitteFehde-board-unlabelled.png")

# At the start of _draw(), after any existing game-state guard:
draw_texture_rect(board_art, Rect2(0, 0, 870, 744), false)
```

Replace the old opaque background and static lot panels with this artwork. Preserve existing `boxes`, click handling, names, prices/troops, building indicators, ownership colors, current/selected outlines, pieces, and event animations. Use translucent ownership fills or colored outlines so the panels remain visible. Remove duplicate division headings, the old central title and procedural cathedral. The central event overlay can continue to appear over the cathedral during dice rolls and battles. Helper text can move into the side panel.

## Validation

Rendered and visually inspected the final PNG. The renderer asserts the output size and exports rectangles directly from the game's layout. All 58 frame positions are sourced from the same array used for click detection. No rules, geometry, executable, or save files were modified. This does not constitute an integration/playtest of the new art in the running game.
