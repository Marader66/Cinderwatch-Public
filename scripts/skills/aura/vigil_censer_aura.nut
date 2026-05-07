// vigil_censer_aura — the cleansed-censer's holy-flame circle.
//
// Inheritance + pattern mirrors ember_of_watch_aura.nut. This is a SMALLER,
// narrower aura that ships with the Vigil Censer weapon (added on equip /
// removed on unequip). It represents the weapon's specific ward, separate
// from the Cinderwarden's personal Ember of the Watch aura — so a Cinderwarden
// wielding the censer gets BOTH auras stacked on their allies, and a brother
// wielding the censer (e.g. after a pickup or trade) gets just this one.
//
// Effects (on wielder + allies within range):
//   IsImmuneToPoison         = true  — no poison tile or status can land
//   IsImmuneToBleeding       = true  — no bleed effects can apply
//   IsImmuneToBleedingInjury = true  — no fresh bleeding injuries from hits
//   MoraleEffectMult        *= 0.8   — the censer's steady hum steadies nerves
//
// Range: 2 tiles base. Narrow by design — the censer wards its immediate
// vicinity, not the whole formation. Stacks additively with Ember of the
// Watch when the Cinderwarden holds it.
//
// Tile-miasma negation is handled by the weapon's onUpdateProperties hook
// (this aura only flips actor-scoped immunity flags). See
// named_vigil_censer.nut onTurnStart for the tile-sweep.
this.vigil_censer_aura <- ::inherit("scripts/skills/aura/rotu_mod_aura_abstract", {
	m = {},

	function create()
	{
		rotu_mod_aura_abstract.create();
		m.ID                   = "actives.vigil_censer_aura";
		m.Name                 = "Vigil Censer";
		m.Description          = "The cleansed censer's holy flame wards poison and bleeding from those who stand beside the bearer.";
		m.ToggleOnDescription  = m.Description;
		m.ToggleOffDescription = m.Description;
		m.Icon = "ui/perks/holyfire_square.png";
		m.IconMini             = "status_effect_01_mini";
		m.Overlay              = "active_128";
		m.SoundVolume          = 1.0;
		m.MaxRange             = 2;   // narrow by design
		m.MinRange             = 1;

		setAsPassiveAura(true);
	}

	function getTooltip()
	{
		local ret = rotu_mod_aura_abstract.getTooltip();
		ret.push({
			id = 10, type = "text", icon = "ui/icons/special.png",
			text = "Wielder and allies within " + m.MaxRange + " tiles are [color=" + ::Const.UI.Color.PositiveValue + "]immune to poison, bleeding, and bleeding injuries[/color]."
		});
		ret.push({
			id = 11, type = "text", icon = "ui/icons/morale.png",
			text = "Morale effects reduced by [color=" + ::Const.UI.Color.PositiveValue + "]20%[/color] for those within the ward."
		});
		return ret;
	}

	// CRITICAL: call parent's onCombatStarted so the aura registers into
	// AuraEffects. Same foot-gun documented throughout the mod stack.
	function onCombatStarted()
	{
		rotu_mod_aura_abstract.onCombatStarted();
	}

	function applyOnUpdate(_affectedTarget, _targetProperties)
	{
		local user = this.getContainer().getActor();
		if (!user.isAlive() || !user.isPlacedOnMap()) return;
		if (!_affectedTarget.isAlive()) return;

		// Wielder (self) and allied targets both receive the ward.
		if (_affectedTarget.getID() == user.getID() || _affectedTarget.isAlliedWith(user)) {
			_targetProperties.IsImmuneToPoison         = true;
			_targetProperties.IsImmuneToBleeding       = true;
			_targetProperties.IsImmuneToBleedingInjury = true;
			_targetProperties.MoraleEffectMult *= 0.8;
		}
	}

	function applyEffectOnActivation(_affectedTarget)
	{
		local user = this.getContainer().getActor();
		if ((_affectedTarget.getID() == user.getID() || _affectedTarget.isAlliedWith(user))
			&& !_affectedTarget.isHiddenToPlayer())
		{
			::Tactical.EventLog.log(
				::Const.UI.getColorizedEntityName(_affectedTarget)
				+ " is warded by the Vigil Censer's cleansing flame."
			);
		}
	}

	// Affect wielder self + allies. No enemy-side effect (the weapon's
	// miasma-tile-negation is a separate mechanism in the weapon itself).
	function isValidTarget(_user, _target)
	{
		if (_target.getID() == _user.getID()) return true;
		return _target.isAlliedWith(_user);
	}
});
