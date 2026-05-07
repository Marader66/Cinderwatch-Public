// lantern_strike_skill — granted to the Cinderwarden at Long Watch Tier II
// (30 Watch Points).
//
// A mid-range light-themed attack. Routes through the damage pipeline like
// Pillar of Light, but single-target and cheaper. On successful hit, it also
// reveals every hidden enemy within 3 tiles of the target — that's the
// mechanical hook that makes the skill distinctive in a BB kit. The
// warden's lantern, thrown hard.
//
// Cost: 5 AP / 20 Fatigue. Range 1-5 tiles. 2-turn cooldown. No ammo (it's
// light, not a crossbow bolt).
this.lantern_strike_skill <- this.inherit("scripts/skills/skill", {
	m = {
		Cooldown      = 0,
		CooldownMax   = 2,
		DamageMin     = 40,
		DamageMax     = 65,
		RevealRadius  = 3
	},

	function create()
	{
		this.m.ID              = "actives.lantern_strike";
		this.m.Name            = "Lantern Strike";
		this.m.Description     = "Hurl a bound flare at the target. The cast is short and hot — and the light spreads. Anything hiding near where it lands stops hiding.";
		this.m.Icon = "ui/perks/lightning_circle.png";  // vanilla fallback
		this.m.IconDisabled    = "ui/perks/perk_70.png";
		this.m.Overlay         = "active_129";
		// 2.1.2 — was sounds/combat/throw_01.wav, suspect phantom (no other
		// mod references it; same risk class as rekindle's scroll_open_01).
		// Replaced preventatively with pov_holy_fire — fits the lantern-light
		// strike thematic.
		// v2.6.0 — SoundOnUse gated on PoV presence (see rekindle_skill.nut
		// for context). Holy-fire sound when PoV loaded; silent fallback
		// otherwise. Earlier versions hard-coded the PoV path.
		if ("HasPoV" in ::getroottable() && ::HasPoV) {
			this.m.SoundOnUse  = [ "sounds/combat/pov_holy_fire_03.wav" ];
			this.m.SoundVolume = 1.0;
		}
		this.m.Type            = ::Const.SkillType.Active;
		this.m.Order           = ::Const.SkillOrder.OffensiveTargeted;
		this.m.IsActive        = true;
		this.m.IsTargeted      = true;
		this.m.IsStacking      = false;
		this.m.IsAttack        = false;
		this.m.IsTargetingActor = false;
		this.m.IsShowingProjectile = false;
		this.m.ActionPointCost = 5;
		this.m.FatigueCost     = 20;
		// v2.4.8 — range trimmed 1-5 → 1-2. Single-target armor-bypass at long
		// range was punching above weight; melee-adjacent / one-step-away
		// keeps the burst threatening without snipe potential.
		this.m.MinRange        = 1;
		this.m.MaxRange        = 2;
	}

	function getTooltip()
	{
		local ret = this.getDefaultTooltip();
		ret.push({
			id = 10, type = "text", icon = "ui/icons/damage_dealt.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]" + this.m.DamageMin + "-" + this.m.DamageMax + "[/color] fire damage to the target."
		});
		ret.push({
			id = 11, type = "text", icon = "ui/icons/vision.png",
			text = "On hit, reveals every hidden enemy within [color=" + ::Const.UI.Color.PositiveValue + "]" + this.m.RevealRadius + "[/color] tiles of the landing spot."
		});
		ret.push({
			id = 12, type = "text", icon = "ui/icons/special.png",
			text = "Ignores armor."
		});
		ret.push({
			id = 13, type = "text", icon = "ui/icons/special.png",
			text = "Cooldown: " + this.m.CooldownMax + " turns (" + ::Math.max(0, this.m.Cooldown) + " remaining)."
		});
		return ret;
	}

	function isUsable()
	{
		if (!this.skill.isUsable()) return false;
		if (this.m.Cooldown > 0) return false;
		local actor = this.getContainer() != null ? this.getContainer().getActor() : null;
		if (actor != null) {
			if (actor.getActionPoints() < this.m.ActionPointCost) return false;
			if (actor.getFatigue() + this.m.FatigueCost > actor.getFatigueMax()) return false;
		}
		return true;
	}

	function onVerifyTarget(_originTile, _targetTile)
	{
		return true;  // any tile in range — the lantern lands, light spreads
	}

	function onUse(_user, _targetTile)
	{
		// Visual flourish at the landing tile. Use the fire-themed particle
		// set; HolyFlameParticles works as a vanilla-safe, verified
		// particle source.
		local particles = ::Const.Tactical.HolyFlameParticles;
		for (local i = 0; i < particles.len(); i++) {
			::Tactical.spawnParticleEffect(
				false, particles[i].Brushes, _targetTile,
				particles[i].Delay, particles[i].Quantity,
				particles[i].LifeTimeQuantity, particles[i].SpawnRate,
				particles[i].Stages
			);
		}

		// Single-target damage — only the actor standing on the targeted tile
		// takes the hit.
		if (_targetTile.IsOccupiedByActor) {
			local target = _targetTile.getEntity();
			if (!_user.isAlliedWith(target)) {
				local dmg = ::Math.rand(this.m.DamageMin, this.m.DamageMax);
				local hitInfo = clone ::Const.Tactical.HitInfo;
				hitInfo.DamageRegular      = dmg;
				hitInfo.DamageDirect       = 1.0;
				hitInfo.BodyPart           = ::Const.BodyPart.Body;
				hitInfo.BodyDamageMult     = 1.0;
				hitInfo.FatalityChanceMult = 1.0;
				target.onDamageReceived(_user, this, hitInfo);
				if (!_user.isHiddenToPlayer()) {
					::Tactical.EventLog.log(
						"[color=#E07A3A]Lantern Strike[/color] lights " +
						::Const.UI.getColorizedEntityName(target) +
						" for [color=" + ::Const.UI.Color.NegativeValue + "]" + dmg + "[/color] damage."
					);
				}
			}
		}

		// Reveal every hidden enemy within RevealRadius of the landing tile.
		// Same hex-ring walk used in rekindle_skill — the lantern is loud.
		local visited = { [_targetTile.ID] = true };
		local frontier = [ _targetTile ];
		for (local r = 0; r < this.m.RevealRadius; r++) {
			local next = [];
			foreach (tile in frontier) {
				for (local i = 0; i < 6; i++) {
					if (!tile.hasNextTile(i)) continue;
					local n = tile.getNextTile(i);
					if (n.ID in visited) continue;
					visited[n.ID] <- true;
					next.push(n);
					if (n.IsOccupiedByActor) {
						local a = n.getEntity();
						if (a == null || _user.isAlliedWith(a)) continue;
						if (a.isHiddenToPlayer()) {
							a.setHidden(false);
						}
					}
				}
			}
			// Include the first ring (targetTile's neighbours) in the reveal
			// even though they're NOT in `next` from this iteration — but
			// they ARE in the frontier already. The nested loop's inner
			// "if IsOccupiedByActor" on `n` catches them. ✓
			frontier = next;
		}

		this.m.Cooldown = this.m.CooldownMax + 1;  // +1 — will decrement at turn end
		return true;
	}

	function onTurnStart()
	{
		if (this.m.Cooldown > 0) this.m.Cooldown -= 1;
	}

	function onCombatFinished()
	{
		this.m.Cooldown = 0;
	}

	function onSerialize(_out)
	{
		this.skill.onSerialize(_out);
		_out.writeI32(this.m.Cooldown);
	}

	function onDeserialize(_in)
	{
		this.skill.onDeserialize(_in);
		this.m.Cooldown = _in.readI32();
	}
});
