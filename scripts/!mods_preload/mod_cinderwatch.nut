// mod_cinderwatch preload
// - Registers with Modern Hooks (::Hooks.register) — same pattern as Golden Throne
//   (NOT ::Mod_ROTU.ModHook.queue, which breaks the PoV/ROTU dep counter).
// - Adds scenario ID to ::Mod_ROTU.ValidOriginIDs so it appears in the scenario
//   select UI.
// - Adds scenario ID constant to ::Mod_ROTU.Scenario for easy reference.
// - Registers the intro event so the scenario can fire it at Day 1.
//
// Requires: mod_ROTUC (ROTU), mod_legends. These are declared baseline
// dependencies of this scenario — without them the scenario won't load, but
// since the mod stack we build for always has both, this is safe.

::Cinderwatch <- {
	ID      = "mod_cinderwatch",
	Version = "2.6.1",
	Name    = "The Cinderwatch"
};

// v2.0.12 — Cinderwatch story arc can fire inside Golden Throne as well,
// when a brother with cinderwarden_background is in the company. The
// helper keys on background ID instead of the Cinderwarden flag because
// GT's wire-in (since GT 2.10.12) clears the flag on the starting
// Cinderwarden to keep only the Emperor as the IsPlayerCharacter origin.
::Cinderwatch._hasCinderwardenInRoster <- function () {
	if (::World == null) return false;
	try {
		foreach (b in ::World.getPlayerRoster().getAll()) {
			if (b == null || !b.isAlive()) continue;
			try {
				if (b.getBackground().getID() == "cinderwarden_background") return true;
			} catch (e) {}
		}
	} catch (e) {}
	return false;
};

// v2.5.0 — FoTN endgame perks for the Cinderwarden. Light path matches the
// "stand alone for power" Watch Points design (Small Target = +MD/RD when
// solitary, the literal mechanic) + Blinding Speed for mobility on the
// polearm/spear identity. Skipped silently if FoTN isn't loaded.
::Cinderwatch._applyFoTNCinderwarden <- function (_warden) {
	if (_warden == null) return;
	if (!("FOTN" in ::getroottable())) return;

	local paths = [
		"scripts/skills/perks/perk_fotn_small_target",
		"scripts/skills/perks/perk_fotn_blinding_speed"
	];
	local skills = _warden.getSkills();
	if (skills == null) return;

	foreach (path in paths) {
		local tail = path.slice(path.find("perk_fotn_") + 10);
		local id = "perk.fotn_" + tail;
		try {
			if (skills.getSkillByID(id) != null) continue;
			skills.add(::new(path));
		} catch (e) {
			::logWarning("[mod_cinderwatch] FoTN perk add failed (" + path + "): " + e);
		}
	}
};

// v2.5.0 — PoV mutagen helper. Mirrors GT's tryApplyPoVMutation pattern
// (golden_knight_ally + golden_fallen_partner). Skipped if PoV isn't
// loaded. _chancePercent of 100 = guaranteed.
::Cinderwatch._applyPoVMutagenCinderwarden <- function (_warden, _chancePercent) {
	if (_warden == null) return;
	if (!("HasPoV" in ::getroottable()) || !::HasPoV) return;
	if (!("TLW" in ::getroottable()) || !("PlayerMutation" in ::TLW)) return;
	if (::Math.rand(1, 100) > _chancePercent) return;

	local pool = [];
	foreach (key, mut in ::TLW.PlayerMutation) {
		if (!("Limit" in mut) || !mut.Limit) continue;
		if (!("Script" in mut) || mut.Script == "") continue;
		pool.push(mut);
	}
	if (pool.len() == 0) return;

	local picked = pool[::Math.rand(0, pool.len() - 1)];
	try {
		local effect = ::new(picked.Script);
		_warden.getSkills().add(effect);
	} catch (e) {
		::logWarning("[mod_cinderwatch] PoV mutagen add failed: " + e);
	}
};

::Cinderwatch.Hooks <- ::Hooks.register(
	::Cinderwatch.ID,
	::Cinderwatch.Version,
	::Cinderwatch.Name
);

// ── Dependencies (shared convention across my mods) ───────────────────
::Cinderwatch.Deps <- {
	Required = {
		mod_legends      = "19.3.17",
		mod_ROTUC        = "3.0.2",
		mod_msu          = "1.2.7",
		mod_modern_hooks = "0.4.0"
	},
	TestedAgainst = {
		mod_fury_of_the_northmen = "0.5.43"
	},
	SaveCompatFrom = "2.0.0"
};

// Deps.Required stays as documentation but no hard-require call —
// testers mix versions to diagnose bugs; blocking load at version
// mismatch gets in the way. Missing deps surface at use-time.

::Cinderwatch.checkDeps <- function () {
	local prefix = "[" + ::Cinderwatch.ID + " v" + ::Cinderwatch.Version + "]";
	local tested = [];
	local drifts = [];
	foreach (modID, wantVer in ::Cinderwatch.Deps.TestedAgainst) {
		if (!::Hooks.hasMod(modID)) continue;
		local mod = ::Hooks.getMod(modID);
		local haveVer   = mod.getVersionString();
		local shortName = modID.find("mod_") == 0 ? modID.slice(4) : modID;
		tested.push(shortName + " " + wantVer);
		// String-equality short-circuit + isSemVer pre-check. Fixes
		// same-version false-positive drift + silences MSU's warning
		// on non-semver versions (Abyss 11.7 log 2026-04-24).
		local matched = (haveVer == wantVer);
		if (!matched) {
			local bothSemver = false;
			try { bothSemver = ::MSU.SemVer.isSemVer(haveVer) && ::MSU.SemVer.isSemVer(wantVer); } catch (e) {}
			if (bothSemver) {
				try { matched = ::MSU.SemVer.compareVersionWithOperator(haveVer, "==", wantVer); } catch (e) {}
			}
		}
		if (!matched) {
			local note = "version compare inconclusive";
			local bothSemver = false;
			try { bothSemver = ::MSU.SemVer.isSemVer(haveVer) && ::MSU.SemVer.isSemVer(wantVer); } catch (e) {}
			if (bothSemver) {
				try {
					note = ::MSU.SemVer.compareVersionWithOperator(haveVer, ">", wantVer)
						? "you're newer, probably fine"
						: "you're older, could miss fixes";
				} catch (e) {}
			}
			drifts.push(modID + ": you have " + haveVer + ", I tested with " + wantVer + " (" + note + ").");
		}
	}
	local summary = "";
	for (local i = 0; i < tested.len(); i++) summary += (i > 0 ? ", " : "") + tested[i];
	if (summary == "") summary = "no soft-tracked mods present";
	::logInfo(prefix + " Tested against " + summary + ". Save-compat from v" + ::Cinderwatch.Deps.SaveCompatFrom + ".");
	foreach (d in drifts) ::logWarning(prefix + " " + d);
};

// Queue after ROTU so Mod_ROTU.Scenario + ValidOriginIDs exist. Queue after
// Legends too so any Legends perk registry we reference is populated.
::Cinderwatch.Hooks.queue(">mod_ROTUC", ">mod_legends", function()
{
	::Cinderwatch.checkDeps();

	// v2.1.0 — Troop spec for the Extinguisher boss. Used by the
	// reckoning event's _launchReckoningCombat helper to spawn the
	// boss into scripted combat. Same pattern as Golden Throne's
	// GoldenGhostDog_Spec (golden_throne preload).
	if ("Const" in ::getroottable() && "World" in ::Const && "Spawn" in ::Const.World
		&& "Troops" in ::Const.World.Spawn
		&& !("CinderwatchExtinguisher_Spec" in ::Const.World.Spawn.Troops)) {
		::Const.World.Spawn.Troops.CinderwatchExtinguisher_Spec <- {
			ID       = ::Const.EntityType.Hexe,
			Variant  = 0,
			Script   = "scripts/entity/tactical/enemies/cinderwatch_extinguisher",
			Strength = 25,
			Cost     = 25,
			Row      = 0
		};
	}

	// Register the scenario ID constant with ROTU.
	if (("Mod_ROTU" in ::getroottable()) && ("Scenario" in ::Mod_ROTU)) {
		if (!("Cinderwatch" in ::Mod_ROTU.Scenario)) {
			::Mod_ROTU.Scenario.Cinderwatch <- "scenario.cinderwatch";
		}
	}

	// Add to ROTU's valid origins list so the scenario select UI renders it.
	if (("Mod_ROTU" in ::getroottable()) && ("ValidOriginIDs" in ::Mod_ROTU)) {
		if (::Mod_ROTU.ValidOriginIDs.find("scenario.cinderwatch") == null) {
			::Mod_ROTU.ValidOriginIDs.push("scenario.cinderwatch");
		}
	}

	// Register the intro event. BB's scenario.onSpawnPlayer fires the event
	// directly by ID; we just have to tell World.Events where to find the
	// script file.
	if (("World" in ::getroottable()) && ("Events" in ::World) && ::World.Events != null) {
		::World.Events.register(
			"event.cinderwatch_intro",
			"scripts/events/events/scenario/cinderwatch_intro_event"
		);
		// v1.1.0 — atmospheric mid-campaign events. Purely flavor; no
		// combat, no progression gate. Each is guarded by a world flag so
		// it fires once. Added to the scenario's special-event pool in
		// `cinderwatch_scenario.onInit`.
		::World.Events.register(
			"event.cinderwatch_road_shrine",
			"scripts/events/events/scenario/cinderwatch_road_shrine_event"
		);
		::World.Events.register(
			"event.cinderwatch_messenger",
			"scripts/events/events/scenario/cinderwatch_messenger_event"
		);

		// v2.0.0 — Western Tower questline (3-beat arc) + 2 atmospheric
		// events interleaved between beats. See
		// scripts/events/events/scenario/cinderwatch_*_event.nut for each
		// event's trigger gates, narrative, and outcome.
		::World.Events.register(
			"event.cinderwatch_western_rumor",
			"scripts/events/events/scenario/cinderwatch_western_rumor_event"
		);
		::World.Events.register(
			"event.cinderwatch_dim_ember",
			"scripts/events/events/scenario/cinderwatch_dim_ember_event"
		);
		::World.Events.register(
			"event.cinderwatch_approach",
			"scripts/events/events/scenario/cinderwatch_approach_event"
		);
		::World.Events.register(
			"event.cinderwatch_dark_grows",
			"scripts/events/events/scenario/cinderwatch_dark_grows_event"
		);
		::World.Events.register(
			"event.cinderwatch_reckoning",
			"scripts/events/events/scenario/cinderwatch_reckoning_event"
		);
		// v2.5.0 — Inheritor succession event. Fires the world-map tick
		// after the Cinderwarden dies at Watch Tier IV (the trait's
		// onDeath sets CinderwatchInheritorPending). The Lantern Passes.
		::World.Events.register(
			"event.cinderwatch_succession",
			"scripts/events/events/scenario/cinderwatch_succession_event"
		);
	}

	::logInfo("[" + ::Cinderwatch.ID + " v" + ::Cinderwatch.Version +
		"] The Cinderwatch scenario registered.");
});

// v2.4.0 — MSU settings page. Master enable + Watch Tier thresholds + base
// aura radius + verbose-log toggle. Tier values read once at preload (the
// StackLib registration block below reads them); changing thresholds takes
// effect on next launch, same convention as TD's settings page.
::Cinderwatch.Hooks.queue(">mod_msu", function () {
	if (!("MSU" in ::getroottable()) || !("Class" in ::MSU) || !("Mod" in ::MSU.Class)) {
		::logWarning("[mod_cinderwatch] MSU not available — settings page skipped");
		return;
	}
	::Cinderwatch.Mod <- ::MSU.Class.Mod(::Cinderwatch.ID, ::Cinderwatch.Version, ::Cinderwatch.Name);
	local page = ::Cinderwatch.Mod.ModSettings.addPage("General");
	page.addBooleanSetting("Enabled", true,
		"Cinderwatch features enabled",
		"Off = Watch Points freeze, no new tier unlocks. Earned tiers stay active.");
	page.addRangeSetting("WatchTierI",   10,   5, 30,  1,
		"Tier I — Watcher's Eye",
		"Points needed for +3 Melee and Ranged Defense.");
	page.addRangeSetting("WatchTierII",  30,  15, 60,  1,
		"Tier II — Lantern Strike",
		"Points needed to unlock the Lantern Strike active.");
	page.addRangeSetting("WatchTierIII", 75,  40, 150, 1,
		"Tier III — Ember Expanded",
		"Points needed for Ember radius +1 and Night Watch.");
	page.addRangeSetting("WatchTierIV", 150,  80, 300, 1,
		"Tier IV — Undying Vigil",
		"Points needed for the Inheritor handoff on death.");
	page.addRangeSetting("EmberRadius",   4,   2, 8,   1,
		"Ember of the Watch base radius",
		"Aura radius. Tier III adds +1 on top.");
	page.addBooleanSetting("VerboseLog", false,
		"Verbose logging",
		"Extra log lines for Watch Point gains and tier changes.");
});

::Cinderwatch.getSetting <- function (_key, _default) {
	try {
		if (!("Mod" in ::Cinderwatch)) return _default;
		local mod = ::Cinderwatch.Mod;
		if (mod == null) return _default;
		local s = mod.ModSettings.getSetting(_key);
		if (s == null) return _default;
		return s.getValue();
	} catch (e) {}
	return _default;
};

// v2.3.1 — Watch Points moves to StackLib (Persistent kind, tier 10/30/75/150).
// legacyField = "WatchPoints" auto-migrates existing campaigns. tier_seen seeded
// from current value so already-crossed tier callbacks don't re-fire.
// v2.4.0 — tier thresholds read from MSU settings; master toggle short-circuits.
::Cinderwatch.Hooks.queue(">mod_lib_stack_skills", function () {
	if (!("StackLib" in ::getroottable())) {
		::logWarning("[mod_cinderwatch] Stack Skills lib not loaded — Watch Points using legacy hand-rolled state");
		return;
	}
	if (!::Cinderwatch.getSetting("Enabled", true)) {
		::logInfo("[mod_cinderwatch] Disabled via mod settings — Watch Points registration skipped");
		return;
	}
	local tiers = [
		::Cinderwatch.getSetting("WatchTierI",    10),
		::Cinderwatch.getSetting("WatchTierII",   30),
		::Cinderwatch.getSetting("WatchTierIII",  75),
		::Cinderwatch.getSetting("WatchTierIV",  150)
	];
	::StackLib.register({
		id          = "cinderwatch.watchpoints",
		kind        = ::StackLib.Kind.Persistent,
		min         = 0,
		tiers       = tiers,
		legacyField = "WatchPoints",
		onTier      = function (_actor, _newTier, _oldTier) {
			// Look up the trait by ID and dispatch to its tier-effect helpers.
			// Closure has no `this`; trait holds the apply/announce logic.
			local trait = _actor.getSkills().getSkillByID("trait.cinderwarden");
			if (trait == null) return;
			try { trait._announceTier(_newTier, _actor); } catch (e) {}
			try { trait._applyTierEffects(_newTier, _actor); } catch (e) {}
		}
	});
	::logInfo("[mod_cinderwatch] Watch Points stack registered with StackLib (tiers " + tiers[0] + "/" + tiers[1] + "/" + tiers[2] + "/" + tiers[3] + ")");
});
