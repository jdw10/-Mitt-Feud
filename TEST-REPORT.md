# Mitt Fued outer-ring update — validation

Tested using the included Godot 4.5 stable runtime.

- Rules suite: 141 passed, 0 failed, including 20 complete seeded AI campaigns.
- Rendered UI suite: 23 checks, 0 failures. Exercises purchase, stationing, six-lot market, end turn, commitment, battle dice, retreat, save/load callbacks, animation timing, pause and action gating.
- Both eight-lot sides split 2 + 6; both seven-lot sides split 3 + 4. Four corner indices retained.
- All four division sizes tested for lot costs, market/barracks costs, partial income, full-division doubled building income and undoubled bare-lot income.
- Passing builds, forward/backward movement, corner landing effects, save/RNG restoration and old-map rejection tested.
- Actual rendered board inspected: artwork intact, no inner trails or hitboxes, Mitt Fued title visible.
- Art exporter completed: three 1740 x 1488 PNGs and 34-entry hitboxes.json, preserving original outer coordinates.
- The sandbox denied shader-cache creation during rendered tests; rendering and checks completed successfully. A staging-only script UID fallback warning used the correct script path.
- Four players and the 16-lot victory target retained by design; no balance retuning or online changes.
