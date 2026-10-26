# Mitt Fued artwork

The original gothic-background.png is unchanged. The live board draws only the 34 outer tile overlays and the new Mitt Fued title, preserving the original outer hitboxes at logical size 870 x 744.

MittFued-board.png, MittFued-board-unlabelled.png and MittFued-alignment-proof.png are regenerated exports at 1740 x 1488, produced by render-board.gd from the current game's geometry and divisions. hitboxes.json now contains 34 rectangles.

To regenerate, run the bundled Godot with --path . --script art/render-board.gd (rendered mode, not headless).

Historical MitteFehde PNGs are retained but are not used by the game; they still depict the removed inner trails.
