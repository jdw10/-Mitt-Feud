# Mitte Fehde v2 validation

Official Godot 4.5 stable, Windows x64, NVIDIA MX570 A / OpenGL compatibility renderer.

**90 rule checks passed; 0 failed.** Includes exact effects for all 28 cards, mandatory dice counts at 1/2/3/5 troops for both sides, fixed commitment, no mid-fight reinforcement, retreat/survivor handling, defeat with reserves remaining, three paired casualties, and explicit absence of a full-division defense bonus. Backward movement is checked on the outer loop, around zero, inside a trail, and across a reversed trail entrance/exit. Six-lot acquisition, prices, bare-lot income, full-division building multiplier and losing that multiplier are checked.

Existing atomic-payment, elimination, once-per-turn income, purchase, building, capture, doubles, victory and save/RNG regressions also pass. Twenty seeded full AI campaigns reached a winner within 15,000 decisions each. Every simulated step checked nonnegative resources, committed-force count and unowned-lot cleanup.

**21 UI checks passed; 0 failed.** Real Button callbacks exercised movement, six-lot purchase, troop stationing, market construction, card phase, end turn, selecting a commitment, battle round, and retreat. Tests verify three dice per side, differing battle-animation frames, dice/building animation activation, input gating, AI pacing, pause timing and automatic release of controls. Manual saving/loading and Rules/Menu opening also ran without engine errors. Rendered board, dice, building and two-color battle screenshots were inspected.

The tests do not establish final balance, guarantee short matches, or constitute a manual full human campaign. Only Windows was run. The package remains an editable offline prototype with a bundled engine, not a signed release/Steam build.

