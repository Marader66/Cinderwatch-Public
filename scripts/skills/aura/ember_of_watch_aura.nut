// ember_of_watch_aura — the Cinderwarden's small personal aura.
//
// Design contrast with Golden Throne's Imperial Presence (10-tile +10 Resolve
// + MD/RD + undead suppression): this one is deliberately SMALL. 4 tiles base,
// buffs only allies, no enemy-side effects at all. The character fantasy is
// "a watchman with a lantern", not "a divine presence radiating out".
//
// Aura effects (on allies within range):
//   +5 Resolve
//   +2 FatigueRecoveryRate (the ember's warmth)
//
// Aura range: 4 base. Can grow by +1 at Watch Tier III (cinderwarden_trait
// writes to `CinderwatchAuraBonus` world flag). Max observed radius 5.
//
// NOTE: inherits `rotu_mod_aura_abstract` — this means ROTU must be loaded,
// matching the scenario's declared baseline dependency. See root-level
// memory `feedback_rotu_legends_baseline.md` for why this is safe.
//
// CRITICAL: the override of onCombatStarted MUST call the parent's
// onCombatStarted(). Without that super-call the abstract never registers the
// aura into AuraEffects and applyOnUpdate never fires. This was a silent bug
// in Golden Throne from v1.7 to v2.3.5 — same pattern here, same trap.
this.ember_of_watch_aura <- ::inherit("scripts/skills/aura/rotu_mod_aura_abstract", {
	m = {},

	function create()
	{
		rotu_mod_aura_abstract.create();
		m.ID                   = "actives.ember_of_watch";
		m.Name                 = "Ember of the Watch";
		m.Description          = "The small, steady warmth of the watchtower's last ember. Allies within the ember's reach stand calmer and rest easier.";
		m.ToggleOnDescription  = m.Description;
		m.ToggleOffDescription = m.Description;
		m.Icon = "ui/perks/holybluefire_circle.png";
		m.IconMini             = "status_effect_02_mini";
		m.Overlay              = "active_129";
		m.SoundVolume          = 1.0;
		m.MaxRange             = 4;   // deliberately modest
		m.MinRange             = 1;

		setAsPassiveAura(true);
	}

	function getTooltip()
	{
		local ret = rotu_mod_aura_abstract.getTooltip();
		ret.push({
			id = 10, type = "text", icon = "ui/icons/bravery.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Resolve for all allies within " + m.MaxRange + " tiles"
		});
		ret.push({
			id = 11, type = "text", icon = "ui/icons/fatigue.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+2[/color] Fatigue Recovery Rate for all allies within " + m.MaxRange + " tiles"
		});
		ret.push({
			id = 12, type = "text", icon = "ui/icons/vision.png",
			text = "Aura radius grows by [color=" + ::Const.UI.Color.PositiveValue + "]+1[/color] at Long Watch Tier III."
		});
		return ret;
	}

	// Read the Watch Tier III range bump at combat start so mid-battle tier
	// advances don't retroactively resize the aura (keeps the fight feeling
	// consistent). Same "next battle" pattern Golden Throne uses.
	function onCombatStarted()
	{
		// v2.4.0 — base radius pulled from MSU settings; Tier III bonus stacks on top.
		local baseRadius = 4;
		try { baseRadius = ::Cinderwatch.getSetting("EmberRadius", 4); } catch (e) {}
		if (::World != null) {
			local bonus = ::World.Flags.getAsInt("CinderwatchAuraBonus");
			m.MaxRange = baseRadius + bonus;
		} else {
			m.MaxRange = baseRadius;
		}
		// CRITICAL: parent registers aura into AuraEffects. Forgetting this
		// silently breaks the whole aura.
		rotu_mod_aura_abstract.onCombatStarted();
	}

	// Called per target per turn while the aura is active.
	function applyOnUpdate(_affectedTarget, _targetProperties)
	{
		local user = this.getContainer().getActor();
		if (!user.isAlive() || !user.isPlacedOnMap()) return;
		if (!_affectedTarget.isAlive()) return;

		if (_affectedTarget.isAlliedWith(user)) {
			_targetProperties.Bravery             += 5;
			_targetProperties.FatigueRecoveryRate += 2;
		}
	}

	function applyEffectOnActivation(_affectedTarget)
	{
		local user = this.getContainer().getActor();
		if (_affectedTarget.isAlliedWith(user) && !_affectedTarget.isHiddenToPlayer()) {
			::Tactical.EventLog.log(
				::Const.UI.getColorizedEntityName(_affectedTarget)
				+ " warms themselves at the Cinderwarden's ember."
			);
		}
	}

	// Allies only — this aura has no enemy-side interaction.
	function isValidTarget(_user, _target)
	{
		return _target.isAlliedWith(_user);
	}
});
