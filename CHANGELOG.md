# The Cinderwatch — Changelog

Mod ID: `mod_cinderwatch`
Deliverable: `zmod_cinderwatch_<version>.zip`

Versions follow semver: **MAJOR.MINOR.PATCH**. Patch = tweaks/fixes, minor = new feature, major = structural overhaul. Source folder name lags the current version by design — it's a working-copy label, not a version number.

Newest first.

---

## 2.6.2 — 2026-05-07

**Patch — silences the "Stack Skills lib not loaded" log warning.** Save-compatible with v2.6.x.

The Cinderwarden's Watch Points persistent counter was registered through a shared library called `mod_lib_stack_skills` (`::StackLib`) that was never publicly shipped. Every public Cinderwatch user has been logging on every campaign start:

```
[Cinderwatch] Stack Skills lib not loaded — Watch Points falling back to legacy state
```

The legacy fallback path still worked (Watch Points lived in `::World.Flags` directly, with the `cinderwarden_trait` doing its own bookkeeping), but the warning was noisy and the dep was hidden.

**Fix:** the library is now embedded directly inside Cinderwatch. No second zip to install, no missing-dep warning. A guard pattern (`if (!("StackLib" in ::getroottable())) { ... }`) means if a sibling mod (Golden Throne v3.0.5+, future scenarios) also embeds the lib, only the first one to load defines the slot — no namespace collisions.

End-user impact: install `zmod_cinderwatch_2-6-2.zip`, the warning goes away, and Watch Points use the full StackLib coordination layer instead of the legacy fallback.

### Files

- `scripts/!mods_preload/mod_cinderwatch.nut` (embed block + 2.6.2 version)
- `scripts/lib/stack_skills/stack_lib.nut` (NEW — embedded lib helper)
- `scripts/lib/stack_skills/combat_hooks.nut` (NEW — embedded lib helper)

---

## 2.6.1 — 2026-05-07

**Patch — phantom-path log spam fix.**

Lantern Strike's `IconDisabled` was set to `gfx/ui/perks/perk_70.png`, which doesn't ship in vanilla / Legends / ROTU. Every time the skill rendered in disabled state (cooldown / out of AP / etc), the engine logged "Unable to open file." Cosmetic only — no gameplay impact — but spammy.

**Fix:** removed the `IconDisabled` line entirely. BB falls back to a default disabled-tint of the main Icon (the lightning-circle), which is what every vanilla skill does anyway.

Save-compat with v2.6.0 — direct in-place upgrade.

---

## 2.6.0 — 2026-05-07 — **First public release**

The 2.x line is feature-complete. This is the first public ship.

### What's in 2.6.0 (rollup of all 2.x development)

**Origin character — the Cinderwarden**
- Mortal warrior. HP 75 / Stamina 95 / MS 75 / RS 50 / MD 25 / RD 15 / Bravery 100 / Init 55. 3-star Bravery + Fatigue + MD; 2-star HP + MS.
- Starting kit: gambeson + chain hauberk, chain hood + kettle hat, billhook, brass lantern trinket.
- Player gender choice at scenario start. The Cinderwarden title stays gender-neutral; voice / body / hair flips on Empress branch via Legends' `setGender(1, true)`.
- Optional integrations (auto-detected): FoTN — adds `perk_fotn_small_target` + `perk_fotn_blinding_speed`. PoV — adds a guaranteed base mutagen.

**Watch Points — the signature mechanic**
- Stand ≥ 4 tiles from any ally at turn start → +1 Watch Point. Persistent across battles.
- Tier I (10): Watcher's Eye — always-on +10% HP, +5 MD, +5 RD, +5 Initiative, +1 Vision.
- Tier II (30): Lantern Strike active (40-65 fire damage, range 1-5, ignores armor, reveals hidden enemies) **plus on-watch synergy** — while ≥ 4 tiles from any ally, gain an additional +7 MD, +7 RD, +5 Initiative, and bleed immunity.
- Tier III (75): Aura radius +1 + Night Watch (every brother treats night as day while warden alive).
- Tier IV (150): Undying Vigil — Inheritor of Flame promotion on warden death.

**Inheritor of Flame promotion (Watch Tier IV)**
- When the Cinderwarden dies at Tier IV, the title and traits transfer to the nearest sworn ally (Warden's Promise carrier).
- `Cinderwarden` + `IsPlayerCharacter` flags transferred. `cinderwarden_trait` + `vigilwalker_trait` granted (Watch Points reset to 0 — a fresh vigil). `wardens_promise_trait` removed (they ARE the warden now).
- Existing background + perk tree preserved. Brass lantern transferred if missing.
- Narrative event "The Lantern Passes" fires on the next world-map tick.

**Brother-wide oath — Warden's Promise**
- Granted to every hire on entry. +5 Bravery always. **MoraleEffectMult ×0 while the Cinderwarden is alive** — the company doesn't rout because someone in front of them is keeping watch.

**Ember of the Watch (aura)**
- Allies-only. 4-tile base radius, 5 at Tier III. +5 Resolve, +2 Fatigue Recovery to allies inside.

**Rekindle (once-per-battle active)**
- Self-centered AoE. Restores 30 Fatigue to warden + allies within 3 tiles. 2 turns of +3 Fatigue Recovery via `ember_kindled_effect`.

**Western Tower questline (5 events, 2 scripted combats)**
- Day 70: Messenger event plants the closed-eye-ring hook.
- Day 150: **Beat 1 — Western Rumor.** Name surfaces.
- Day 170-240: Atmospheric oil-choice event.
- Day 250: **Beat 2 — The Approach (scripted combat).** Mender scouts (4 Cultists + 1 Hexe leader). Bypass option preserved for players who skip.
- Day 270-305: Atmospheric mood-setter ("the morning of the crow").
- Day 310: **Beat 3 — The Reckoning (scripted boss combat).** The Extinguisher — a former Cinderwatch brother who let the western tower's ember die. ROTU-champion-scaled, miasma-flavored boss kit. The Vigil Censer (a polearm + flail dual-class legendary) drops from his corpse on victory.

**The Vigil Censer (Beat 3 reward)**
- Dual-class polearm + flail. Both PolearmTree and FlailTree perks apply.
- 50-75 regular damage, 1.1 armor mult, 0.35 direct. Head-hit 25%. Condition 80.
- 2-tile cleansing ward on equip — wielder + allies become immune to poison, bleeding, and bleeding injuries.
- +15% damage, +10% armor damage vs `monstrous` / `undead` / `beast`.

### Required mods

- Modern Hooks ≥ 0.4.0
- MSU ≥ 1.2.7
- Legends ≥ 19.3.17
- ROTU Core ≥ 2.1.2

### Optional mods (graceful integrations)

- **Fury of the Northmen** — Cinderwarden gets `perk_fotn_small_target` + `perk_fotn_blinding_speed` (Light path).
- **Path of the Vattghern** — Cinderwarden gets a guaranteed PoV base mutagen.
- **Three Musketeers** — Cinderwatch's questline events fire inside 3M campaigns when a Cinderwarden brother is in the company.
- **Golden Throne** — same crossover path. GT 2.10.12+ also includes a test wire-in adding the Cinderwarden as a 5th GT starter (skipped cleanly if Cinderwatch isn't installed).

### Save compatibility

Save files from version 2.0.0 forward load on this build. Older v1.x campaigns aren't supported on v2.x — start a fresh run.

---

## Pre-2.6 internal versions (development log)

The 2.x line spent April-May 2026 iterating between internal-only builds. No public releases shipped during that period; v2.6.0 is the first public ship of the 2.x line.

Highlights from internal development:

- **v2.6.0**: Beat 2 scripted combat (was narrated). Critical phantom-sound fix — `pov_holy_fire_*` paths gated on PoV presence so no-PoV stacks don't crash on Rekindle / Lantern Strike.
- **v2.5.0**: Inheritor of Flame promotion (Tier IV warden death promotes nearest sworn ally to full origin) + FoTN/PoV optional layering + female body sprite via `setGender(1, true)`.
- **v2.4.9**: Vigil Censer dual-class polearm + flail.
- **v2.1.0**: Beat 3 scripted combat (was narrated); Vigil Censer drops from Extinguisher's corpse loot.
- **v2.0.0**: Western Tower questline (5 events). Extinguisher entity + Vigil Censer item ship ready.

---

## 2.0.8 — 2026-04-24

**Dep-check — dropped hard `Hooks.require()` gate.** Matches 2.8.5 / 11.9 / 1.3.17 change. Deps are documentation only now; no load-time block on version mismatch.

## 2.0.7 — 2026-04-24

**Hotfix — dep-check false-positive drift + MSU non-semver warning.** Same helper fix as 2.8.4 / 11.8 / 1.3.16. String-equality short-circuit + `isSemVer` pre-check.

## 2.0.6 — 2026-04-24

**Hotfix — dep-check convention (2.0.5) used wrong mod IDs + wrong getMod contract.** Mirror fix of Golden Throne 2.8.3:

1. ROTU's registered ID is `mod_ROTUC` — was using the zip filename in `Deps.Required`. Fixed.
2. `mod_fotn` → `mod_fury_of_the_northmen` in `Deps.TestedAgainst`.
3. `::Hooks.getMod(id)` throws on unregistered mods instead of returning null. Pre-check with `::Hooks.hasMod(id)` added.

2.0.5 broke scenario registration via the same chain — queue function threw during checkDeps. 2.0.6 restores working load. Source folder kept at `zmod_cinderwatch_2.0.5/` for this hotfix.

## 2.0.5 — 2026-04-24

**Convention — dependency declaration block.** New `::Cinderwatch.Deps` table in the preload declares hard requires, soft tested-against versions, and save-compat range. Same shape applied across my four BB mods; see `docs/dep_check_usage.md` for the spec. Zero gameplay impact.

Save-compat: unchanged from 2.0.0. No serialization touches.

## 2.0.4 — 2026-04-24

**Compat bump — ROTU 3.0.2.** No code changes. The three ROTU API calls Cinderwatch makes (`::Mod_ROTU.Scenario.Cinderwatch` registration, `::Mod_ROTU.ValidOriginIDs` push, `::Mod_ROTU.Mod.ModSettings.getSetting("DifficultyScaling")` in the Extinguisher entity) verified against 3.0.2 source — all stable. Legends dep floor implicitly bumps to **19.3.17+** (ROTU 3.0.2's new minimum). Requires fresh campaign because ROTU 3.0.2 is a replacement, not a patch over 2.x.

## 2.0.3 — 2026-04-23

**Fix (defensive — scenario.onHiredByScenario hardened):** Each of the three steps in the hire handler (PlayerCharacter flag check, Warden's Promise trait add, mood update) now wrapped in its own try/catch. Prevents a single transient failure on a freshly-hired brother from aborting the whole hire sequence and leaving them half-initialized without the Promise trait.

**Audit (clean — no other same-pattern bugs found):**
- **Golden Throne partner events:** already use outer `try/catch` around every roster iteration — not vulnerable to the same loop pattern the Cinderwatch events had.
- **Unified Stack Patch:** no `foreach`/`improveMood` patterns at all — purely hook-based fixes.
- **Enemy Inspector:** no `improveMood` patterns.
- **Golden Brand skill signatures:** all 12 methods verified against Legends' canonical signatures (`onBeingAttacked`, `onTargetHit`, `onAllyKilled`, `onDamageReceived`, etc.). No other signature mismatches beyond the `onDamageReceived` fix that shipped in Golden Throne v2.6.3.
- **Brace-balance smoke check:** all 23 Cinderwatch `.nut` files have balanced `{}` — no syntactic issue that would prevent load.

## 2.0.2 — 2026-04-22

**Fix:** Road Shrine "Lighting of a Candle" loop — root cause identified. User reported the first event wouldn't stop firing; specifically the LIGHT branch of `cinderwatch_road_shrine_event`. Diagnosis: `start(_event)` iterated `::World.getPlayerRoster().getAll()` and called `bro.improveMood(...)` on each brother without per-brother try/catch. A single misbehaving roster entity (transient null state / off-field / wounded) would throw, aborting the screen's start-function mid-loop. The screen would render incompletely, `onFinish` would not run, `CinderwatchRoadShrineSeen` world flag would not set → next world-tick the event re-queues → infinite loop.

**Fix applied to all 7 Cinderwatch event files** (audit of pattern across the whole scenario):
- Every `foreach (bro in ::World.getPlayerRoster().getAll()) { bro.improveMood(...) }` wrapped in outer try/catch + per-brother inner try/catch.
- If one brother misbehaves, the others still get their mood update, the loop completes, the event's terminal option returns, `onFinish` fires, the seen-flag sets, no re-fire possible.
- 8 unguarded loops fixed: 1 in Road Shrine LIGHT (the user-hit case), 1 in Road Shrine GIFT, 1 each in dark_grows / approach / messenger / western_rumor / reckoning, 3 in dim_ember (all three option branches).

Pattern now consistent across every event's mood-loop: outer try wraps the foreach, inner try wraps each `improveMood` call. Equivalent to defensive iteration in a Legends scenario hook.

## 2.0.1 — 2026-04-22

**Fix (defensive — intro event re-fire guard):** User reported "the first event wouldn't stop firing" on a v2.0.0 campaign. BB doesn't log event-fires by default so the log didn't capture a specific loop; adding belt-and-suspenders gates regardless of root cause:
- New once-flag `CinderwatchIntroSeen`. `cinderwatch_intro_event.onFinish` sets it; `cinderwatch_scenario.onSpawnPlayer` checks it before firing the intro.
- Intro event's `onUpdateScore` now explicitly `m.Score = 0` — makes sure BB's event-pool scoring can never pick it up on a retry cycle.
- Intro event's `onFinish` now sets the once-flag. (Previously missing — was relying on BB's default event-lifecycle to prevent re-fire, which apparently isn't bulletproof.)

Completed intro now can never replay. If the bug was actually in a different event (Beat 1 Rumor, Road Shrine, Messenger, etc.), this patch doesn't address it yet — need log with the specific event name to narrow further.

## 2.0.0 — 2026-04-22

**Feat:** **Western Tower questline** — full 3-beat narrative arc closing the silver-ring hook planted by the Day-70 messenger event in v1.1.0.

- **Beat 1** (Day ≥ 150) `cinderwatch_western_rumor_event` — a name surfaces. A former Cinderwatch brother/sister, thought dead in the plague year, is alive and travelling with the Flesh Menders.
- Atmospheric (Day 170-240) `cinderwatch_dim_ember_event` — lantern oil choice: pay full, dim, or gutter. Gold/mood/renown deltas.
- **Beat 2** (Day ≥ 250) `cinderwatch_approach_event` — Flesh Mender scouts intercept the company. Engage or bypass; narrated combat.
- Atmospheric (Day 270-305) `cinderwatch_dark_grows_event` — the morning of the crow. Pure mood-setter.
- **Beat 3** (Day ≥ 310) `cinderwatch_reckoning_event` — confrontation at the dead western tower. The Extinguisher reveals themselves. Narrated fight. Vigil Censer drops to stash.

**Feat:** **The Extinguisher** (`cinderwatch_extinguisher.nut`) — boss entity ships ready. Former Cinderwatch brother, ROTU champion-scaled for Day 310 (HP ~320+ at scale), wields the vanilla miasma flail (FoTN hook attaches `fotn_miasma_flail_effect` — spews miasma tiles). Gender paired opposite the Cinderwarden via `CinderwardenIsFemale` world flag. Pale grey-green tint across all 19 sprite layers. **v2.0 does NOT spawn the entity in scripted combat** (Beat 3 narrates); entity + onDeath flag-setter are ready for v2.1 scripted-combat wiring.

**Feat:** **The Vigil Censer** (`named_vigil_censer.nut`) — signature reward, 2H flail. Extends `named_weapon` directly, NOT the vanilla miasma_flail (inheriting from miasma_flail would pull in FoTN's miasma-on-hit hook). Grants censer moveset via `Legends.Actives`: CenserStrike + CenserCastigate + LegendRangedLash. On equip, attaches a 2-tile ally-only `vigil_censer_aura` — wielder + allies inside become `IsImmuneToPoison` + `IsImmuneToBleeding` + `IsImmuneToBleedingInjury` with MoraleEffectMult ×0.8. +15% damage + +10% armor damage vs monstrous / undead / beast foes. Drops to stash at Beat 3 resolution.

**Feat:** `vigil_censer_aura` — the cleansed censer's ward. Inherits `rotu_mod_aura_abstract`; small 2-tile radius by design.

**Scope deferrals (v2.1 pipeline):**
- Real scripted tactical combat at Beats 2 + 3 (narrated in v2.0).
- Flesh Mender retinue entity file — can reskin `fault_finder` or `grand_diviner`.
- Western tower location entity for the scripted-combat trigger.

File count: 13 → 23. Major version bump per convention (new scenario arc + new mechanics tie-in).

## 1.3.3 — 2026-04-22

**Chore:** Warden's Promise trait icon swapped from vanilla `perk_15` → `holyfire_circle.png`. Same hand-with-flame icon the Cinderwarden's own trait uses — shared visual says every sworn brother carries the mark of the watch-fire.

**Fix:** Brass lantern trinket icon. Was `tools/torch.png` which doesn't exist (log showed "Unable to open file" error at item render — BB tool-folder filenames all use `_NN_70x70` suffix). Swapped to `accessory/oms_amphora_full.png` — a Legends accessory brass-vessel that reads as "filled ember-vessel".

## 1.3.2 — 2026-04-22

**Fix (phantom brushes from first real load):**
- `bust_base_hedge_knight` — phantom despite reading plausibly vanilla. Swapped to `bust_base_crusader` (verified in Legends' `legends_crusader_scenario` + Golden Throne's Emperor).
- `figure_player_militia` — phantom. Legends comments out every non-crusader `figure_player_*` reference. Removed the `ModCustomPartyLook` override entirely; BB's default mercenary figure fits the modest-order-of-watchers fantasy.

## 1.3.1 — 2026-04-22

**Chore:** Cinderwarden trait icon swap. Was vanilla `perk_01` fallback. Now `holyfire_circle.png` — same hand-with-flame icon Golden Throne's Emperor trait and Pillar of Light use. Shared visual language for watch-fire-tenders across both scenarios.

## 1.3.0 — 2026-04-22

**Feat:** **Night Watch at Long Watch Tier III.** While the Cinderwarden is alive and Tier III (75+ Watch Points) has been reached, the whole company treats night as day (`IsAffectedByNight = false`, applied per-actor). Paired with the existing Tier III aura-radius bump. Tier IV (Undying Vigil — ember-passes-on-death) unchanged.

Implementation: world flag `CinderwatchNightWatch` set by `cinderwarden_trait._applyTierEffects` at Tier III entry. Read by both `cinderwarden_trait.onUpdate` (self) and `wardens_promise_trait.onUpdate` (brothers).

## 1.2.1 — 2026-04-22

**Fix (phantom-const freeze on new campaign — 3 fixes):**
- `cinderwarden_background.nut`: `BeastsTree` → `BeastTree` (singular, per Legends' `z_perks_tree_enemy.nut:7`).
- `cinderwarden_background.nut`: `PikemanClassTree` → `MilitiaClassTree` (pikeman tree doesn't exist; militia is the watchman-fantasy equivalent).
- `cinderwatch_scenario.nut`: `PerkDefs.Spearwall` → `PerkDefs.FortifiedMind`, `PerkDefs.PolearmMastery` → `PerkDefs.Brawny` (weapon-skill masteries aren't registered as PerkDefs). Verified replacements against `mod_legends-19.3.17/!!config/perks_defs.nut`.

All four perk-tree + PerkDef references in the mod re-audited.

## 1.2.0 — 2026-04-22

**Feat:** Player-facing gender choice. New `GENDER` screen prepended to the intro event. Female branch calls `setOriginGender(true)` which finds the `Cinderwarden`-flagged roster member, sets `actor.m.Gender = 1`, sets `CinderwardenIsFemale` world flag. Title stays "The Cinderwarden" in both cases (the order didn't gender-mark its titles). **Caveat:** body sprite reflects BB's roll at spawn time; swapping post-hoc was out of scope.

## 1.1.0 — 2026-04-22

**Feat:** Two atmospheric mid-journey events — `cinderwatch_road_shrine_event` (Day ≥ 15, 3-option flavor choice at a wayside shrine) and `cinderwatch_messenger_event` (Day ≥ 70, messenger returns with the silver-ring clue). Plants `CinderwatchWesternTowerRumored` flag for the future western-tower questline to gate on (later paid off in v2.0.0).

## 1.0.0 — 2026-04-22

Initial release. Full scenario:
- **The Cinderwatch** scenario — inherits `tainted_world_scenario` for ROTU compat. Difficulty 2, starting roster 4 brothers (Cinderwarden + retired_soldier + monk + hedge_knight).
- **The Cinderwarden** origin background — deliberately mortal, 3-star Bravery/Fatigue/MD talents, billhook + brass lantern loadout, gambeson + hauberk + chain hood + kettle hat.
- **Signature mechanic — The Long Watch.** Watch Points at turn start when ≥ 4 tiles from any ally. Tier unlocks at 10/30/75/150: +MD/RD, Lantern Strike active, aura-radius bump, Undying Vigil handoff on death.
- **Ember of the Watch** aura — 4-tile ally-only, +5 Resolve, +2 Fatigue Recovery.
- **Rekindle** active — once per battle, 3-tile self-centered stamina restore + ember-kindled 2-turn buff.
- **Lantern Strike** active — Watch Tier II unlock, fire damage + hidden-enemy reveal.
- **Warden's Promise** brother-wide oath — +5 Bravery + morale anchor while Cinderwarden lives.
- **Vigilwalker** passive — anti-surprise + first-round stun/daze immunity + quiet bearing.
- **Inheritor of Flame** — Tier IV capstone handoff.
- **Intro event** — 4 screens (letter / tower / promise / brief).

---

Full git log for this mod: `git log --all -- 'zmod_cinderwatch_*'`.
