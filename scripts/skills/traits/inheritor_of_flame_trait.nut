// inheritor_of_flame_trait — granted to the nearest living ally when the
// Cinderwarden dies at Long Watch Tier IV (150+ Watch Points).
//
// Design: the capstone isn't "the Cinderwarden resurrects" — this scenario
// explicitly has no divine resurrection. Instead, when the warden falls at
// the peak of their vigil, the ember finds a new hand. The receiving brother
// becomes a lesser flame-bearer: they get a modest stat bump and inherit the
// "Ember of Watch" aura at reduced radius, keeping the company's identity
// alive even though the scenario's campaign-end check (scenario.onCombatFinished)
// will end the run if no `Cinderwarden` flag is in the roster.
//
// So: this trait is consolation, not continuation. It keeps the closing
// battle dignified — the company rallies for one more push around the
// person who caught the ember — but the campaign still ends.
//
// (A future version could promote the inheritor to full Cinderwarden status
// and keep the campaign going. That's a much bigger change — flag transfer,
// background swap, perk-tree re-roll — so it's parked as a v2+ idea.)
this.inheritor_of_flame_trait <- ::inherit("scripts/skills/traits/character_trait", {
	m = {},

	function create()
	{
		character_trait.create();
		m.ID          = "trait.inheritor_of_flame";
		m.Name        = "Inheritor of the Flame";
		m.Icon = "ui/perks/fire_circle.png";  // vanilla fallback
		m.Description = "The ember passed. Whoever held it last held it at the end. Whoever holds it now carries what was left.";
		m.Type        = m.Type | ::Const.SkillType.Trait;
	}

	function onUpdate(_properties)
	{
		// Modest consolation bonuses. Not a replacement Emperor.
		_properties.Bravery      += 10;
		_properties.MeleeDefense += 3;
		_properties.Initiative   += 5;
		// Anchor morale — this brother holds the center of whatever's left.
		_properties.MoraleEffectMult *= 0.5;
	}

	// When an inheritor is added, spawn a small visual flourish and announce
	// it in the event log so the moment reads clearly.
	function onAfterAdded()
	{
		local actor = this.getContainer().getActor();
		if (actor == null) return;
		if (actor.isHiddenToPlayer()) return;
		if (::Tactical != null && ::Tactical.isActive()) {
			this.spawnIcon("status_effect_79", actor.getTile());
		}
	}
});
