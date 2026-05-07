// rekindle_skill — the Cinderwarden's once-per-battle self-centered AoE.
//
// When used, restores 30 Fatigue to the warden and every ally within 3 tiles,
// and applies `ember_kindled_effect` (a 2-turn +3 Fatigue Recovery buff) to
// each. Thematically: the warden shares the ember's warmth.
//
// Self-centered — no targeting cursor. Fires from the user's own tile.
// Cost 4 AP / 20 Fatigue (the act of sharing warmth takes its own effort).
// Once per battle, reset in onCombatStarted.
this.rekindle_skill <- this.inherit("scripts/skills/skill", {
	m = {
		UsedThisBattle = false,
		Radius         = 3,
		FatigueRestore = 30
	},

	function create()
	{
		this.m.ID                = "actives.rekindle";
		this.m.Name              = "Rekindle";
		this.m.Description       = "Draw the ember close and share its warmth. Restores stamina to you and every ally within three tiles, and leaves them breathing easier for a turn or two.";
		this.m.Icon = "ui/perks/burning_hands_circle_02.png";    // vanilla fallback
		this.m.IconDisabled      = "ui/perks/perk_18.png";
		this.m.Overlay           = "active_129";
		// v2.6.0 — SoundOnUse gated on PoV presence. The pov_holy_fire_*.wav
		// sounds are PoV-shipped, not vanilla; on a no-PoV stack they're
		// phantom paths that hard-crash BB ("Unable to open file" → row
		// critical). README claims PoV is optional, so we honor that:
		// holy-fire sound when PoV is loaded, silent otherwise. Earlier
		// versions (v2.1.2 - v2.5.0) hard-coded the PoV path and would
		// crash any no-PoV install.
		if ("HasPoV" in ::getroottable() && ::HasPoV) {
			this.m.SoundOnUse  = [ "sounds/combat/pov_holy_fire_02.wav" ];
			this.m.SoundVolume = 1.0;
		}
		this.m.Type              = ::Const.SkillType.Active;
		this.m.Order             = ::Const.SkillOrder.UtilityTargeted;
		this.m.IsActive          = true;
		this.m.IsTargeted        = false;
		this.m.IsStacking        = false;
		this.m.IsAttack          = false;
		this.m.IsTargetingActor  = false;
		this.m.IsShowingProjectile = false;
		this.m.ActionPointCost   = 4;
		this.m.FatigueCost       = 20;
		// MinRange/MaxRange nominal — IsTargeted=false skips the targeting UI
		// entirely, so this is just to satisfy the base skill class's checks.
		this.m.MinRange          = 0;
		this.m.MaxRange          = 0;
	}

	function getTooltip()
	{
		local ret = this.getDefaultTooltip();
		ret.push({
			id = 10, type = "text", icon = "ui/icons/fatigue.png",
			text = "Restores [color=" + ::Const.UI.Color.PositiveValue + "]" + this.m.FatigueRestore + "[/color] Fatigue to the Cinderwarden and every ally within " + this.m.Radius + " tiles."
		});
		ret.push({
			id = 11, type = "text", icon = "ui/icons/fatigue.png",
			text = "Affected allies gain [color=" + ::Const.UI.Color.PositiveValue + "]+3 Fatigue Recovery[/color] for 2 turns."
		});
		ret.push({
			id = 12, type = "text", icon = "ui/icons/special.png",
			text = this.m.UsedThisBattle
				? "[color=" + ::Const.UI.Color.NegativeValue + "]Ember already shared this battle.[/color]"
				: "Once per battle."
		});
		return ret;
	}

	function isUsable()
	{
		if (!this.skill.isUsable()) return false;
		if (this.m.UsedThisBattle) return false;
		local actor = this.getContainer() != null ? this.getContainer().getActor() : null;
		if (actor != null) {
			if (actor.getActionPoints() < this.m.ActionPointCost) return false;
			if (actor.getFatigue() + this.m.FatigueCost > actor.getFatigueMax()) return false;
		}
		return true;
	}

	// No targeting — fires from caster position. BB calls onUse(_user,
	// _targetTile) with _targetTile == _user.getTile() for IsTargeted=false
	// skills.
	function onUse(_user, _targetTile)
	{
		local centerTile = _user.getTile();

		// Gather affected actors: self + every ally within `Radius` tiles.
		// Hex-ring walk: ring 0 is the center, rings 1..R expand outward.
		// BB doesn't expose a "tiles within N" helper, so walk manually using
		// the 6-direction adjacency (hasNextTile / getNextTile).
		local affected = [ _user ];
		local visited  = { [centerTile.ID] = true };
		local frontier = [ centerTile ];
		for (local r = 0; r < this.m.Radius; r++) {
			local nextFrontier = [];
			foreach (tile in frontier) {
				for (local i = 0; i < 6; i++) {
					if (!tile.hasNextTile(i)) continue;
					local n = tile.getNextTile(i);
					if (n.ID in visited) continue;
					visited[n.ID] <- true;
					nextFrontier.push(n);
					if (n.IsOccupiedByActor) {
						local a = n.getEntity();
						if (a != null && a.isAlive() && a != _user
							&& _user.isAlliedWith(a))
						{
							affected.push(a);
						}
					}
				}
			}
			frontier = nextFrontier;
		}

		// Apply the effect: fatigue restore + status effect (2-turn buff).
		foreach (a in affected) {
			a.setFatigue(::Math.max(0, a.getFatigue() - this.m.FatigueRestore));
			// Add the ember-kindled status if not already present; refresh
			// if it is.
			local existing = a.getSkills().getSkillByID("effects.ember_kindled");
			if (existing != null) {
				try { existing.m.TurnsLeft = 2; } catch (e) {}
			} else {
				try {
					a.getSkills().add(::new("scripts/skills/effects/ember_kindled_effect"));
				} catch (e) {
					::logWarning("[mod_cinderwatch] ember_kindled add failed: " + e);
				}
			}
			// Visual: small flourish at each affected actor.
			try { this.spawnIcon("status_effect_01", a.getTile()); } catch (e) {}
		}

		this.m.UsedThisBattle = true;

		if (!_user.isHiddenToPlayer() && ::Tactical != null && ::Tactical.isActive()) {
			::Tactical.EventLog.log(
				"[color=#E07A3A]Rekindle — " +
				::Const.UI.getColorizedEntityName(_user) +
				" shares the ember's warmth with " + (affected.len() - 1) + " ally or allies.[/color]"
			);
		}
		return true;
	}

	function onCombatStarted()
	{
		this.m.UsedThisBattle = false;
	}

	function onSerialize(_out)
	{
		this.skill.onSerialize(_out);
		_out.writeBool(this.m.UsedThisBattle);
	}

	function onDeserialize(_in)
	{
		this.skill.onDeserialize(_in);
		this.m.UsedThisBattle = _in.readBool();
	}
});
