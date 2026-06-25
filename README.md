# Vallidyn University

A single-player adaptation of my PF2e campaign *Vallidyn University* — a
PF2e/SF2e Remastered CRPG with Octopath-style 2.5D HD-2D presentation and a
visual-novel daily-life layer. Personal / non-commercial. Built in **Godot 4.7 /
GDScript** (statically typed).

The build is deliberately **rules-engine-first**: a headless, deterministic,
fully unit-tested rules core is Phase 1 and must be correct before any
story/VN/presentation work. See the project spec for the full architecture and
build order.

## Status

Phase 1 headless rules core — milestones 1–3 and 5–7 done (M4 deferred),
verified with GUT:

- **M1 — Scaffold:** project, folder tree, `core/ids.gd` central id registry,
  resource schema stubs (`resources/*.gd`), GUT installed, console smoke harness.
- **M2 — Dice + Check + Degrees:** `core/dice.gd`, `core/degrees.gd`,
  `core/checks/check.gd`. The universal d20 resolver — `d20 + ability +
  proficiency + Σ modifiers vs DC → degree`, with nat-1/nat-20 swing.
- **M3 — Modifier stack:** `core/modifiers/`. PF2e stacking — typed
  circumstance/status/item/difficulty bonuses take-highest, penalties
  take-worst, untyped stacks.
- **M5 — Conditions engine:** `core/conditions/`. Full Remastered list (~40),
  valued + binary, with take-highest stacking, implications (grabbed → off-guard
  + immobilized), end-of-turn decrement/expiry, and the modifiers each condition
  imposes — emitted as `Modifier`s filtered by a stat-tag context, so they
  resolve through the M3 stack and interact correctly (a status and a
  circumstance penalty both apply; two status penalties take the worst).
- **M6 — Action economy + Strike:** `core/actions/`. 3 actions + reaction per
  turn, the Multiple Attack Penalty (−5/−10, −4/−8 agile), and a full Strike:
  attack through the universal check, hit/crit by degree, crit-doubled damage,
  then the target's immunity/weakness/resistance. Consumes M5 conditions —
  off-guard lowers the target's AC; frightened/enfeebled/clumsy bite the attack.
  Introduces a lean runtime `core/creature/creature.gd` (the stat block M4 will
  add derivation to).
- **M7 — Grid + movement + LoS:** `core/encounter/`. Square grid with the
  5/10/5/10 diagonal distance rule; reach and flanking geometry (flanking →
  off-guard, feeding M6); difficult-terrain (×2) path cost and a Dijkstra
  reachable set that stays correct under the alternating diagonal rule; and
  line-of-sight / cover (none/lesser/standard/greater → AC bonus).

Everything is deterministic (rolls run against an **injected** `RandomNumberGenerator`
— the core never calls global `randi()`).

## Layout

```
core/        headless rules engine (no Godot scenes) — the faithful PF2e math
resources/   class_name Resource schemas (authored data shape)
data/        imported content (.tres) — populated by the Foundry importer later
tools/       editor-only Foundry JSON → .tres importer (later)
game/        presentation / Godot scenes (combat, character, sprites, VN…) (later)
tests/       GUT suites mirroring core/
main.gd/.tscn console smoke entry point
```

## Running it

Requires **Godot 4.7** (standard, GDScript build) on your `PATH` and the bundled
**GUT 9.7** addon (in `addons/gut/`, committed).

```bash
# Smoke test — links the core and runs a deterministic check, then quits.
godot --headless

# Full unit-test suite (GUT), headless.
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Current suite: **126 tests / 1392 assertions, all passing.**
A rule isn't "done" until it has tests — every new core feature ships with a GUT
suite before the next milestone begins.
