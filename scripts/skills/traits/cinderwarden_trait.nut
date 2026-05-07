// cinderwarden_trait — the mechanical driver of the origin character.
//
// CORE MECHANIC: The Long Watch
// -----------------------------
// At the start of each of the Cinderwarden's turns, measure the distance to
// the nearest allied actor on the battlefield. If that distance is ≥ 4 tiles,
// grant +1 Watch Point. Otherwise no change. Watch Points accumulate across
// the entire campaign (serialized), so a patient player earns tier unlocks
// across many battles rather than needing to grind in a single fight.
//
// TIER UNLOCKS
// ------------
//   Tier I   — 10 Watch Points (rebalanced v2.4.1):
//              Always-on: +10% Hitpoints, +5 MeleeDefense, +5 RangedDefense,
//              +5 Initiative, +1 Vision (Mandate-T1-parity baseline).
//              Solo bonus (≥4 tiles from any ally, the same condition that
//              earns Watch Points): additional +7 MD, +7 RD, +5 Initiative,
//              IsImmuneToBleeding. The long-eyed soldier reads the fight,
//              and standing the long watch sharpens that further.
//
//   Tier II  — 30 Watch Points:
//              Grants the `lantern_strike_skill` active. A mid-range
//              crossbow-like light attack that deals moderate damage and
//              reveals hidden enemies within 3 tiles of the target.
//
//   Tier III — 75 Watch Points:
//              Permanent +1 tiles to Ember-of-Watch aura radius. Implemented
//              by bumping the `CinderwatchAuraBonus` world flag, same pattern
//              Golden Throne's Purge IV uses for `GoldenEmperorAuraBonus`.
//
//   Tier IV  — 150 Watch Points (capstone):
//              "Undying Vigil". When the Cinderwarden dies, the nearest ally
//              gains the `inheritor_of_flame_trait` — a small echo of the
//              ember that keeps the company from routing immediately. See
//              onDeath below for handoff logic.
//
// WHY WATCH POINTS ARE EARNED BY ISOLATION
// ----------------------------------------
// BB's default positioning meta pushes every character to cluster for aura
// overlap and rotation support. The Cinderwarden inverts this — they earn
// their signature power standing at the formation edge, literally keeping
// watch. This gives the origin a distinct feel from a "center of the line"
// captain/leader archetype.
//
// The 4-tile isolation threshold is chosen so a reasonable formation can
// still have the Cinderwarden on a flank without pushing them into genuine
// peril. Solo deep flanking also qualifies but isn't necessary.
this.cinderwarden_trait <- ::inherit("scripts/skills/traits/character_trait", {
	m = {
		// Primary state — serialized across the campaign.
		WatchPoints      = 0,
		MilestonesHit    = 0,
		// Bookkeeping: if the Cinderwarden somehow has Lantern Strike granted
		// already (save-load re-init), don't double-grant. Standard hasSkill
		// check handles this defensively below; this mirror just avoids noise.
		LanternStrikeGranted = false
	},

	function create()
	{
		character_trait.create();
		m.ID          = "trait.cinderwarden";
		m.Name        = "The Cinderwarden";
		// v1.3.1: swapped from vanilla perk_01 fallback to holyfire_circle
		// (user preference 2026-04-22). Same "hand-with-flame" icon the
		// Golden Throne stack uses on the Emperor trait, Pillar of Light,
		// Golden Command, etc. Reads as the shared visual language of
		// watch-fire-tenders across both scenarios.
		m.Icon = "ui/perks/holyfire_circle.png";
		m.Description = "A vigil-keeper of the plague-struck order. Their strength grows from patience — from standing watch at the line's edge, from seeing what others miss.";
		m.Titles      = [ "the Watcher", "of the Eastern Watch", "of the Ember" ];
		m.Type        = m.Type | ::Const.SkillType.Trait;
	}

	function getTooltip()
	{
		local ret = [
			{ id = 1, type = "title",       text = this.getName() },
			{ id = 2, type = "description", text = this.m.Description }
		];

		local tier = this._getTier();
		local next = [10, 30, 75, 150, 9999][tier];

		ret.push({
			id = 10, type = "text", icon = "ui/icons/vision.png",
			text = "[color=#E07A3A]The Long Watch[/color]: "
				+ this._getWP() + " Watch Points"
				+ (tier < 4 ? " — next tier at " + next : " — the final tier stands")
		});

		local pos = ::Const.UI.Color.PositiveValue;
		local neg = ::Const.UI.Color.NegativeValue;
		if (tier >= 1) {
			ret.push({ id = 11, type = "text", icon = "ui/icons/melee_defense.png",
				text = "[color=#E07A3A]Tier I — Watcher's Eye[/color] (always-on): [color=" + pos + "]+10% HP[/color], [color=" + pos + "]+5 MD/RD[/color], [color=" + pos + "]+5 Initiative[/color], [color=" + pos + "]+1 Vision[/color]." });
		}
		if (tier >= 2) {
			ret.push({ id = 12, type = "text", icon = "ui/icons/action_points.png",
				text = "[color=#E07A3A]Tier II — Lantern Strike[/color]: an active short-range skill that reveals hidden enemies around the target." });
			// Live on-watch indicator — synergy bonus moved to Tier II in v2.4.8.
			local onWatch = false;
			try { onWatch = this._isOnWatch(); } catch (e) {}
			ret.push({ id = 12.5, type = "text", icon = "ui/icons/special.png",
				text = onWatch
					? "[color=#E07A3A]Standing watch[/color] — synergy bonus [color=" + pos + "]ACTIVE[/color]: additional [color=" + pos + "]+7 MD[/color], [color=" + pos + "]+7 RD[/color], [color=" + pos + "]+5 Initiative[/color], [color=" + pos + "]immune to bleeding[/color]."
					: "[color=#E07A3A]Standing watch[/color] — synergy bonus [color=" + neg + "]inactive[/color] (need ≥4 tiles from any ally). Would grant +7 MD/RD, +5 Init, bleed-immune." });
		}
		if (tier >= 3) ret.push({ id = 13, type = "text", icon = "ui/icons/special.png",
			text = "[color=#E07A3A]Tier III — Ember Expanded[/color]: Ember of the Watch aura radius +1 permanently. The company no longer suffers [color=" + ::Const.UI.Color.PositiveValue + "]night penalties[/color] while you live." });
		if (tier >= 4) ret.push({ id = 14, type = "text", icon = "ui/icons/days_wounded.png",
			text = "[color=#E07A3A]Tier IV — Undying Vigil[/color]: if the Cinderwarden falls, the nearest sworn brother (Warden's Promise) inherits the ember." });

		// v2.4.8 — post-Tier-IV bonus indicator.
		local wpNow = this._getWP();
		if (wpNow >= 150) {
			local extraPct = ::Math.min(25, (wpNow - 150) / 10);
			local capped = (extraPct >= 25);
			ret.push({ id = 14.5, type = "text", icon = "ui/icons/leveled_up.png",
				text = "[color=#E07A3A]Long Vigil[/color]: +" + extraPct + "% to HP, Stamina, MD, RD"
					+ (capped ? " [color=" + pos + "](capped)[/color]" : " — next +1% at " + (150 + (extraPct + 1) * 10) + " WP, cap +25%") });
		}

		ret.push({
			id = 15, type = "text", icon = "ui/icons/morale.png",
			text = "[color=#E07A3A]Watch Points[/color] are gained at turn start while standing four or more tiles from any ally. Keep the edge."
		});

		return ret;
	}

	// Applied passive effects for earned tiers. onUpdate runs every stat-
	// recalculation, so this keeps the tier-I bonus always fresh.
	function onUpdate(_properties)
	{
		// v2.3.1: tier reads go through StackLib (with legacy fallback).
		local tier = this._getTier();
		if (tier >= 1) {
			// v2.4.8 — split: Tier I is the always-on baseline only.
			// The on-watch synergy bonus + Lantern Strike unlock graduate
			// to Tier II — earn the steady block first, then the synergy
			// payout for living the same condition that earns Watch Points.
			_properties.HitpointsMult *= 1.10;
			_properties.MeleeDefense  += 5;
			_properties.RangedDefense += 5;
			_properties.Initiative    += 5;
			_properties.Vision        += 1;
		}
		if (tier >= 2 && this._isOnWatch()) {
			_properties.MeleeDefense    += 7;
			_properties.RangedDefense   += 7;
			_properties.Initiative      += 5;
			_properties.IsImmuneToBleeding = true;
		}
		if (tier >= 3) {
			_properties.IsAffectedByNight = false;
		}

		// v2.4.8 — post-Tier-IV progression. Every 10 WP past 150 grants
		// +1% to HP, Stamina, MD, RD via multiplicative stat mults. Capped
		// at +25% (so 400 WP is the new ceiling). Long campaigns get a
		// slow grind reward beyond the capstone instead of the count
		// becoming inert.
		local wp = this._getWP();
		if (wp >= 150) {
			local extraPct = ::Math.min(25, (wp - 150) / 10);
			if (extraPct > 0) {
				local mult = 1.0 + (extraPct / 100.0);
				_properties.HitpointsMult     *= mult;
				_properties.StaminaMult       *= mult;
				_properties.MeleeDefenseMult  *= mult;
				_properties.RangedDefenseMult *= mult;
			}
		}
	}

	// Mirrors the onTurnStart isolation check at minDist >= 4. Returns
	// true when the actor is solo (or no ally on the field). Defensive
	// false-default if not in tactical / not placed on map — onUpdate
	// also runs out-of-combat for character-screen display, and we want
	// the baseline numbers to show there (player learns the bonus from
	// the tooltip, not from the hidden +7 ghost).
	function _isOnWatch() {
		local actor = this.getContainer().getActor();
		if (actor == null) return false;
		try {
			if (!actor.isPlacedOnMap()) return false;
			if (::Tactical == null || !::Tactical.isActive()) return false;
			local myTile = actor.getTile();
			local myID   = actor.getID();
			local minDist = 99;
			local foundAny = false;
			foreach (ally in this.getAllyActors(actor)) {
				if (ally == null) continue;
				if (ally.getID() == myID) continue;
				if (!ally.isAlive() || !ally.isPlacedOnMap()) continue;
				foundAny = true;
				local d = myTile.getDistanceTo(ally.getTile());
				if (d < minDist) minDist = d;
			}
			if (!foundAny) return true; // alone on the field counts
			return minDist >= 4;
		} catch (e) {}
		return false;
	}

	// ── Internal: WP read/write/tier with StackLib fallback ─────────────

	function _getWP() {
		local actor = this.getContainer().getActor();
		if (actor == null) return this.m.WatchPoints;
		if ("StackLib" in ::getroottable()) {
			try { return ::StackLib.get(actor, "cinderwatch.watchpoints"); } catch (e) {}
		}
		return this.m.WatchPoints;
	}

	function _addWP(_n) {
		local actor = this.getContainer().getActor();
		if (actor == null) return this.m.WatchPoints;
		if ("StackLib" in ::getroottable()) {
			try { return ::StackLib.add(actor, "cinderwatch.watchpoints", _n); } catch (e) {}
		}
		// Legacy fallback — replicate hand-rolled tier-advance dispatch.
		this.m.WatchPoints += _n;
		local newTier = this._computeTier();
		if (newTier > this.m.MilestonesHit) {
			this.m.MilestonesHit = newTier;
			this._announceTier(newTier, actor);
			this._applyTierEffects(newTier, actor);
		}
		return this.m.WatchPoints;
	}

	function _getTier() {
		local actor = this.getContainer().getActor();
		if (actor == null) return this.m.MilestonesHit;
		if ("StackLib" in ::getroottable()) {
			try { return ::StackLib.getTier(actor, "cinderwatch.watchpoints"); } catch (e) {}
		}
		return this.m.MilestonesHit;
	}

	// The core loop — at the start of each Cinderwarden turn, check isolation
	// and award a Watch Point if earned.
	//
	// v2.2.2: wrapped in try/catch + adds diagnostic event-log line on every
	// firing showing measured minDist + closest ally name. Per
	// feedback_skill_onupdate_combat_init_guards memory rule. Diagnostic line
	// is gated on `CinderwatchWatchDebug` world flag (off by default; enable
	// via dev console: ::World.Flags.set("CinderwatchWatchDebug", true);).
	function onTurnStart()
	{
		try {
			local actor = this.getContainer().getActor();
			if (actor == null || !actor.isAlive()) return;

			// v2.2.3: unconditional logInfo so we can see in log.html whether
			// onTurnStart is even firing, even if isPlacedOnMap() returns false
			// or some other guard short-circuits.
			::logInfo("[cinderwarden_trait.onTurnStart] entry: actor=" + actor.getName()
				+ ", placed=" + actor.isPlacedOnMap() + ", WP=" + this._getWP());

			if (!actor.isPlacedOnMap()) return;

			local myTile = actor.getTile();
			local myID   = actor.getID();
			local minDist = 99;
			local closestAlly = null;
			local closestName = "(none)";
			local allyCount = 0;
			local allies = this.getAllyActors(actor);
			foreach (ally in allies) {
				if (ally == null) continue;
				// v2.2.4: BB Squirrel `==` on actor refs doesn't reliably filter
				// self — same logical actor returned via getAllInstances vs
				// getContainer().getActor() yields distinct object refs that
				// compare unequal. Diagnosed when minDist always == 0 with
				// closestName == self. Compare by stable getID() instead.
				if (ally.getID() == myID) continue;
				if (!ally.isAlive() || !ally.isPlacedOnMap()) continue;
				allyCount += 1;
				local d = myTile.getDistanceTo(ally.getTile());
				if (d < minDist) {
					minDist = d;
					closestAlly = ally;
					try { closestName = ally.getName(); } catch (e) { closestName = "(unnamed)"; }
				}
			}

			// v2.2.3: ALSO logInfo the measurement unconditionally so we get
			// a paper trail in log.html regardless of in-combat event-log guards.
			::logInfo("[cinderwarden_trait.onTurnStart] allies=" + allyCount
				+ ", minDist=" + minDist + ", closest=" + closestName
				+ ", grant=" + (minDist >= 4 ? "YES" : "no"));

			// Diagnostic — emits to the in-game event log when the debug flag is on.
			// v2.2.3: switched from `== true` to truthy check (BB's Flags.get may
			// coerce types on save/load, and `1 == true` isn't reliably truthy in
			// Squirrel). Toggle via dev console:
			//   ::World.Flags.set("CinderwatchWatchDebug", true);
			if (::World != null
				&& ::World.Flags.get("CinderwatchWatchDebug")
				&& !actor.isHiddenToPlayer()
				&& ::Tactical != null
				&& ::Tactical.isActive())
			{
				local edge = (minDist >= 4) ? "[color=#7ACC55](edge kept — +1)[/color]"
					: "[color=#CC7755](too close — no grant)[/color]";
				::Tactical.EventLog.log(
					"[color=#E07A3A]Watch Debug[/color] — "
					+ allyCount + " allies tracked, closest = " + closestName
					+ " at " + minDist + " hex. Threshold ≥ 4. " + edge
				);
			}

			// If the nearest ally is ≥ 4 tiles away, the Cinderwarden is keeping
			// proper watch. Grant +1. Also grant if there's no ally at all on
			// the battlefield (solo-warden edge case — minDist stays 99).
			//
			// v2.3.1: lib's _addWP() handles tier callbacks automatically.
			// Legacy fallback in _addWP also dispatches tier effects when lib
			// isn't loaded.
			if (minDist >= 4) {
				local now = this._addWP(1);

				if (now % 5 == 0
					&& !actor.isHiddenToPlayer()
					&& ::Tactical != null
					&& ::Tactical.isActive())
				{
					::Tactical.EventLog.log(
						"[color=#E07A3A]The Long Watch[/color] — "
						+ ::Const.UI.getColorizedEntityName(actor)
						+ " keeps the edge. " + now + " Watch Points."
					);
				}
			}
		} catch (e) {
			::logWarning("[mod_cinderwatch] cinderwarden_trait.onTurnStart guarded throw: " + e);
		}
	}

	// Helper — return an array of all allied actors the Cinderwarden can see.
	// Uses the faction's ally query if available; falls back to the tactical
	// state's roster iteration if not.
	function getAllyActors(_self)
	{
		local out = [];
		if (::Tactical == null || !::Tactical.isActive()) return out;
		local allEntities = ::Tactical.Entities.getAllInstances();
		if (allEntities == null) return out;
		// v2.2.4: filter by getID() not `==`. See onTurnStart comment.
		local selfID = -1;
		try { selfID = _self.getID(); } catch (e) { return out; }
		// allEntities is an array-of-arrays keyed by faction ID.
		foreach (factionList in allEntities) {
			foreach (e in factionList) {
				if (e == null) continue;
				if (e.getID() == selfID) continue;
				if (!e.isAlive()) continue;
				if (!_self.isAlliedWith(e)) continue;
				out.push(e);
			}
		}
		return out;
	}

	function _computeTier()
	{
		if (this.m.WatchPoints >= 150) return 4;
		if (this.m.WatchPoints >= 75)  return 3;
		if (this.m.WatchPoints >= 30)  return 2;
		if (this.m.WatchPoints >= 10)  return 1;
		return 0;
	}

	function _announceTier(_tier, _actor)
	{
		if (_actor.isHiddenToPlayer() || ::Tactical == null || !::Tactical.isActive()) return;
		local text;
		switch (_tier) {
			case 1: text = "Watcher's Eye — the fight slows under long attention."; break;
			case 2: text = "Lantern Strike — the watcher learns to throw light at what hides."; break;
			case 3: text = "Ember Expanded — the ember's warmth reaches further than before."; break;
			case 4: text = "Undying Vigil — what burns long does not die alone."; break;
			default: return;
		}
		::Tactical.EventLog.log(
			"[color=#E07A3A]The Long Watch — Tier " + _tier + ": " + text + "[/color]"
		);
	}

	// Apply the one-time effects of a tier advance (skill grants, world flag
	// bumps). Idempotent via hasSkill checks — safe to call more than once.
	function _applyTierEffects(_tier, _actor)
	{
		// Tier II — grant Lantern Strike skill
		if (_tier >= 2 && !this.m.LanternStrikeGranted) {
			if (!_actor.getSkills().hasSkill("actives.lantern_strike")) {
				try {
					_actor.getSkills().add(::new("scripts/skills/actives/lantern_strike_skill"));
				} catch (e) {
					::logWarning("[mod_cinderwatch] Lantern Strike grant failed: " + e);
				}
			}
			this.m.LanternStrikeGranted = true;
		}

		// Tier III — bump aura radius world flag by 1. Guarded so it only
		// fires once (the `_tier > this.m.MilestonesHit` check in the caller
		// already enforces this, but a belt-and-suspenders world-flag counter
		// means a save-load re-entry can't accidentally stack it).
		//
		// v1.3.0: Tier III also activates the Night Watch — lights the
		// `CinderwatchNightWatch` flag. While set AND the Cinderwarden is
		// alive, the company is IsAffectedByNight=false (applied per-actor
		// in wardens_promise_trait.onUpdate, and self-applied in the
		// Cinderwarden's own onUpdate above). Set every tier-III entry so
		// a save-load scenario where the flag was lost still re-establishes
		// it — cheap, idempotent write.
		if (_tier >= 3 && ::World != null) {
			if (!::World.Flags.get("CinderwatchAuraTierBumped")) {
				local bonus = ::World.Flags.getAsInt("CinderwatchAuraBonus");
				::World.Flags.set("CinderwatchAuraBonus", bonus + 1);
				::World.Flags.set("CinderwatchAuraTierBumped", true);
			}
			::World.Flags.set("CinderwatchNightWatch", true);
		}

		// Tier IV effect fires on death, not on tier advance — see onDeath.

		// v2.2.0 — visual aura. Apply tier-scaled gold glow.
		this._applyVisualAura(_actor, _tier);
	}

	// v2.2.0 — visual indicator of Watch Points tier. champion_glow halo
	// tinted gold, intensity scales with tier (T0 = invisible, T4 = full).
	// Re-applied on every onCombatStarted + onApplyAppearance so it
	// survives sprite redraws.
	function _applyVisualAura(_actor, _tier) {
		if (_actor == null) return;
		if (!_actor.hasSprite("before_socket")) return;
		try {
			local glow = _actor.getSprite("before_socket");
			if (_tier <= 0) {
				glow.Visible = false;
				return;
			}
			glow.setBrush("champion_glow");
			// Gold-amber palette ramping with tier
			//   T1 = warm soft amber, T4 = bright pale gold
			local saturation = 0.4 + (_tier * 0.15);   // 0.55 → 1.00
			local hex = ["#a87830", "#c89040", "#e8b050", "#f0d680"][_tier - 1];
			glow.Color = this.createColor(hex);
			glow.Saturation = saturation;
			glow.Visible = true;
		} catch (e) {
			::logWarning("[mod_cinderwatch] Watch-tier glow apply failed: " + e);
		}
	}

	function onApplyAppearance() {
		character_trait.onApplyAppearance();
		try {
			local actor = this.getContainer().getActor();
			if (actor != null) this._applyVisualAura(actor, this._getTier());
		} catch (e) {}
	}

	function onCombatStarted() {
		character_trait.onCombatStarted();
		try {
			local actor = this.getContainer().getActor();
			if (actor != null) this._applyVisualAura(actor, this._getTier());
		} catch (e) {}
	}

	// Tier IV capstone: on the Cinderwarden's death, find the nearest still-
	// alive allied brother and grant them `inheritor_of_flame_trait`. The
	// inheritor becomes a lantern-bearer themselves — keeps the company from
	// routing, keeps a small echo of Ember of Watch alive.
	function onDeath(_fatalityType)
	{
		// MSU's skill_container iterates skills with a single _fatalityType arg.
		// The 4-arg entity-style signature threw "wrong number of parameters"
		// on every death; pull death tile from the actor instead (fixed v2.4.5).
		character_trait.onDeath(_fatalityType);

		if (this._getTier() < 4) return;

		local actor = this.getContainer().getActor();
		if (actor == null) return;

		local deathTile = null;
		try { deathTile = actor.getTile(); } catch (e) {}
		if (deathTile == null) return;

		// v2.4.8 — handoff filtered to sworn watch-allies only (carriers of
		// Warden's Promise). The ember passes only to one who took the oath.
		// Hired brothers always carry it (granted in scenario.onHiredByScenario);
		// random non-Cinderwatch entities on the field do not.
		local minDist = 99;
		local chosen  = null;
		local allies  = this.getAllyActors(actor);
		foreach (ally in allies) {
			if (ally == null || !ally.isAlive()) continue;
			if (!ally.isPlacedOnMap()) continue;
			if (ally.getFlags().has("Cinderwarden")) continue;  // skip self
			if (ally.getSkills().getSkillByID("trait.wardens_promise") == null) continue;
			local d = deathTile.getDistanceTo(ally.getTile());
			if (d < minDist) {
				minDist = d;
				chosen = ally;
			}
		}

		if (chosen == null) return;
		if (chosen.getSkills().getSkillByID("trait.inheritor_of_flame") != null) return;

		try {
			chosen.getSkills().add(::new("scripts/skills/traits/inheritor_of_flame_trait"));
			if (!chosen.isHiddenToPlayer() && ::Tactical != null && ::Tactical.isActive()) {
				::Tactical.EventLog.log(
					"[color=#E07A3A]Undying Vigil — the ember passes to "
					+ ::Const.UI.getColorizedEntityName(chosen) + ".[/color]"
				);
			}
		} catch (e) {
			::logWarning("[mod_cinderwatch] Inheritor grant failed: " + e);
		}

		// v2.5.0 — full Inheritor promotion. Transfer the Cinderwarden +
		// IsPlayerCharacter flags, grant the warden trait stack so the
		// inheritor's own Watch Points + Vigilwalker passives kick in
		// (their watch starts fresh — WatchPoints back at 0). Remove their
		// wardens_promise_trait — they ARE the warden now, not sworn to
		// one. Keep their existing background + perk tree intact (their
		// earned levels stay; the promotion is identity, not a class
		// change). Transfer the brass lantern trinket if missing. Fire the
		// succession narrative event on the next world tick.
		try {
			chosen.getFlags().set("IsPlayerCharacter", true);
			chosen.getFlags().set("Cinderwarden", true);
		} catch (e) { ::logWarning("[mod_cinderwatch] flag transfer failed: " + e); }

		try {
			if (chosen.getSkills().getSkillByID("trait.cinderwarden") == null) {
				chosen.getSkills().add(::new("scripts/skills/traits/cinderwarden_trait"));
			}
			if (chosen.getSkills().getSkillByID("trait.vigilwalker") == null) {
				chosen.getSkills().add(::new("scripts/skills/traits/vigilwalker_trait"));
			}
			// Strip Warden's Promise — can't be sworn to yourself. The
			// inheritor's morale anchor now comes from BEING the warden,
			// not from one above them.
			chosen.getSkills().removeByID("trait.wardens_promise");
		} catch (e) { ::logWarning("[mod_cinderwatch] inheritor trait reshape: " + e); }

		// Brass lantern transfer — only if the inheritor doesn't already
		// have one (some hired brothers may carry their own).
		try {
			local items = chosen.getItems();
			local hasLantern = false;
			foreach (slot in [::Const.ItemSlot.Accessory, ::Const.ItemSlot.Bag]) {
				try {
					local stash = items.getAllItemsAtSlot(slot);
					if (stash != null) {
						foreach (it in stash) {
							if (it != null && it.getID() == "misc.brass_lantern_trinket") {
								hasLantern = true; break;
							}
						}
					}
				} catch (e) {}
				if (hasLantern) break;
			}
			if (!hasLantern) {
				try { items.equip(::new("scripts/items/misc/brass_lantern_trinket")); } catch (e) {}
			}
		} catch (e) { ::logWarning("[mod_cinderwatch] lantern transfer: " + e); }

		// Queue the succession narrative event for the next world tick.
		// Set the InheritorPending flag; the event reads it via isValid().
		try {
			::World.Flags.set("CinderwatchInheritorPending", true);
			::World.Flags.set("CinderwatchInheritorName", chosen.getName());
		} catch (e) {}
	}

	function onSerialize(_out)
	{
		character_trait.onSerialize(_out);
		_out.writeI32(this.m.WatchPoints);
		_out.writeI32(this.m.MilestonesHit);
		_out.writeBool(this.m.LanternStrikeGranted);
	}

	function onDeserialize(_in)
	{
		character_trait.onDeserialize(_in);
		this.m.WatchPoints          = _in.readI32();
		this.m.MilestonesHit        = _in.readI32();
		this.m.LanternStrikeGranted = _in.readBool();
	}
});
