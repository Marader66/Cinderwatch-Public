// ember_kindled_effect — applied to allies inside the Cinderwarden's
// Rekindle radius. Lasts 2 turns, granting +3 Fatigue Recovery Rate each
// turn. Removed at combat end.
//
// This is a non-stacking status: re-applying while active just refreshes
// TurnsLeft back to 2 (handled by rekindle_skill.onUse, not here).
this.ember_kindled_effect <- this.inherit("scripts/skills/skill", {
	m = {
		TurnsLeft = 2
	},

	function create()
	{
		this.m.ID                  = "effects.ember_kindled";
		this.m.Name                = "Ember-Kindled";
		this.m.Description         = "Warmed by the Cinderwarden's shared ember. Fatigue recovers faster while the ember's light remains.";
		this.m.Icon = "ui/perks/burning_hands_circle_01.png";  // vanilla fallback
		this.m.IconMini            = "status_effect_01_mini";
		this.m.Overlay             = "status_effect_01";
		this.m.Type                = this.Const.SkillType.StatusEffect;
		this.m.IsActive            = false;
		this.m.IsStacking          = false;
		this.m.IsRemovedAfterBattle = true;
	}

	function getTooltip()
	{
		return [
			{ id = 1, type = "title",       text = this.getName() },
			{ id = 2, type = "description", text = this.m.Description },
			{ id = 10, type = "text", icon = "ui/icons/fatigue.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]+3[/color] Fatigue Recovery Rate." },
			{ id = 11, type = "text", icon = "ui/icons/special.png",
				text = "Remaining: " + this.m.TurnsLeft + " turn(s)." }
		];
	}

	function onUpdate(_properties)
	{
		_properties.FatigueRecoveryRate += 3;
	}

	// BB effects use either onTurnEnd or onTurnStart to decrement their
	// timers. onTurnEnd is the convention for "effect was applied this
	// turn, first tick fires at end of turn" — so we use TurnsLeft-- then
	// self-remove when expired. onRefresh is called by rekindle_skill to
	// reset the counter, but since rekindle writes m.TurnsLeft directly we
	// don't need a function definition here.
	function onTurnEnd()
	{
		this.m.TurnsLeft -= 1;
		if (this.m.TurnsLeft <= 0) {
			this.removeSelf();
		}
	}
});
