# The Cinderwatch

A custom Battle Brothers scenario where you play the Cinderwarden — last surviving member of a plague-struck watchtower order, riding west to learn why the companion tower's ember has gone dark. Mortal origin. No resurrection. No divine aura. The character's strength is positional discipline, an old brass lantern, and the order's small, stubborn signature: stand at the formation's edge, keep watch, light the dark.

A deliberate counterpoint to god-king scenarios. The story is gothic-duty rather than messianic.

## Install

Grab the latest zip from the [Releases page](https://github.com/Marader66/Cinderwatch-Public/releases) and drop it into your Battle Brothers `data/` folder. No extraction needed.

```
zmod_cinderwatch_<version>_INN.zip
```

## Required mods

| Mod | Minimum version |
|-----|-----------------|
| Modern Hooks | 0.4.0 |
| MSU | 1.2.7 |
| Legends | 19.3.17 |
| ROTU Core Inn | 2.1.2 |

**Battle Brothers DLC required:** Legends needs the main DLC to run — Beasts & Exploration, Warriors of the North, Blazing Deserts, and Of Flesh and Faith. Cinderwatch itself doesn't gate content on any specific DLC, but since Legends is a hard dependency, your install effectively needs the full set.

## Optional mods (graceful integrations)

These are all soft-detected. Cinderwatch runs without them; if any are present, you get extra layering on the Cinderwarden:

- **Fury of the Northmen (FoTN)** — adds two Light-path FoTN endgame perks to the Cinderwarden: Small Target (+MD/RD when standing solitary, the literal Watch Points philosophy as a passive) and Blinding Speed (mobility / disorient).
- **Path of the Vattghern (PoV)** — adds a guaranteed PoV base mutagen on the Cinderwarden (vs the 40% chance most PoV-using mods roll).
- **Three Musketeers** — Cinderwatch's questline events fire inside Three Musketeers campaigns when a Cinderwarden brother is in the company.
- **Golden Throne** — the questline ALSO fires inside Golden Throne campaigns when a Cinderwarden brother is in the company. GT 2.10.12+ includes a test wire-in that adds the Cinderwarden as a 5th GT starter brother (skipped cleanly if Cinderwatch isn't installed).

## What you get

### The Cinderwarden

- HP 75 / Stamina 95 / MS 75 / RS 50 / MD 25 / RD 15 / Bravery 100 / Init 55
- 3-star Bravery + Fatigue + MD; 2-star HP + MS
- Starting kit: gambeson + chain hauberk, chain hood + kettle hat (open-face, the lantern is your vision), billhook, brass lantern trinket
- Starting perks: Battle Forged, Colossus, Steel Brow, Gifted, Rotation, Fortified Mind, Brawny
- Origin traits: Cinderwarden Trait (Watch Points driver), Vigilwalker Trait (anti-surprise immunities), Tough, Determined
- Player gender choice at scenario start — male or female; the title stays "The Cinderwarden" in both cases (the order didn't gender-mark its titles).

### Watch Points — the signature mechanic

The Cinderwarden earns power by *staying at the formation's edge*. At the start of each of their turns, if the nearest allied actor is ≥ 4 tiles away (or no ally is on the field at all), they gain +1 Watch Point. Persistent across battles.

Tier unlocks:
- **Tier I (10 pts)** — Watcher's Eye: always-on **+10% HP, +5 MD, +5 RD, +5 Initiative, +1 Vision**.
- **Tier II (30 pts)** — Lantern Strike active (40-65 fire damage at range 1-5, reveals hidden enemies, ignores armor, 2-turn CD) **plus an on-watch synergy bonus**: while standing ≥ 4 tiles from any ally, gain an additional **+7 MD, +7 RD, +5 Initiative, and bleed immunity**.
- **Tier III (75 pts)** — Ember Expanded: aura radius +1; Night Watch (every brother in the company treats night as day while the Cinderwarden is alive)
- **Tier IV (150 pts)** — Undying Vigil: on the Cinderwarden's death, the title and traits pass to their nearest sworn ally. The campaign continues. The watch holds.

### Inheritor of Flame promotion (v2.5.0)

When the Cinderwarden dies at Watch Tier IV, the title doesn't just end. The brass lantern passes to the nearest sworn brother (a Warden's Promise carrier) and they become the warden — `Cinderwarden` flag transferred, `IsPlayerCharacter` flag transferred, Cinderwarden Trait + Vigilwalker added (Watch Points reset to 0 — their own vigil begins fresh), Warden's Promise removed (they ARE the warden now, can't be sworn to themselves).

The inheritor keeps their existing background and earned perk tree. The promotion is identity, not a class change.

A short narrative event fires the next world-map tick — *"The Lantern Passes."* — closing the moment.

### Ember of the Watch (aura)

Small radius (4 tiles base, 5 at Watch Tier III). Allies only. +5 Resolve, +2 Fatigue Recovery to allies inside.

### Rekindle (once-per-battle active)

Self-centered, no target cursor. Restores 30 Fatigue to the Cinderwarden + every ally within 3 tiles. Plus 2 turns of +3 Fatigue Recovery via the `ember_kindled` effect. 4 AP / 20 Fatigue.

### Warden's Promise (every hired brother)

Granted to every hire on entry. +5 Bravery always; **morale penalties zero out while the Cinderwarden is alive** — the company holds because someone in front of them is keeping watch. If the Cinderwarden dies (and isn't replaced via Inheritor promotion), the morale anchor drops and the company has to find its own footing.

### Vigilwalker (Cinderwarden passive)

First-round stun/daze immunity. Quiet morale (×0.85). Anti-surprise — clears any "waiting for next round" state at combat start.

### Western Tower questline (Day 70 → 310)

Five-event narrative arc + two real scripted combats:

| Day | Event | Type |
|-----|-------|------|
| 15+ | Road Shrine | Atmospheric |
| 70+ | The Messenger | Atmospheric — plants the closed-eye ring hook |
| 150+ | Western Rumor | Beat 1 — narrative |
| 170-240 | The Dim Ember | Atmospheric |
| 250+ | **The Approach** | **Beat 2 — scripted combat** (Mender scouts, 4× Cultist + 1× Hexe leader) |
| 270-305 | The Dark Grows | Atmospheric — the morning of the crow |
| 310+ | **The Reckoning** | **Beat 3 — scripted boss combat** (the Extinguisher) |

The Reckoning is a one-on-one boss fight against the Extinguisher — a former Cinderwatch brother who let the western tower's ember die, took up a Flesh Mender corruption censer, and is waiting at the dead tower for someone of the order to come settle it. ROTU-champion-scaled, miasma-flavored boss kit.

Defeat him and the Vigil Censer drops from his corpse — a 2H polearm-and-flail dual-class weapon (works with both PolearmTree and FlailTree perks), Holy / Two-Handed / Named, with a 2-tile cleansing ward (allies inside become immune to poison + bleeding + bleeding injuries). The brass becomes clean again. The order ends in a way it gets to choose.

If you retreat or lose the fight, the arc stays open — try again when the company is mended.

## Save compatibility

Save files from version 2.0.0 forward load on this build. Older Cinderwatch campaigns from v1.x aren't supported on v2.x; start a fresh run.

The v2.5.0 Inheritor promotion + v2.6.0 scripted Beat 2 combat are both backwards-compatible additions — existing saves continue running. New mechanics activate when their preconditions hit.

## Tone note

The mod treats death matter-of-factly. Brothers die, the lantern moves, the watch continues. The signature mechanic exists because the order's lesson was that the ember does not need a particular hand. Names of dead wardens get folded into a recordkeeper's book. There's a gentle gothic register throughout — Mender humming under their breath at dusk, dawn the wrong shade of grey, a brass lantern at the centre of the camp. If you want a triumphant power-fantasy origin, this isn't that one. The Golden Throne is.

## License

MIT. See `LICENSE`.

## Credits

- Scenario design + Squirrel implementation: EC + Marader66
- Battle Brothers / Legends mod / ROTU / Modern Hooks / MSU communities for the patterns this mod was built on
