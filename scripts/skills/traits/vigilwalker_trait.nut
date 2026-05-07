// vigilwalker_trait — passive immunities that reflect the watchtower order's
// signature training. Unlike the Emperor's full morale/injury immunity stack,
// this is narrow and legible: anti-surprise + first-round stun immunity +
// quiet bearing (lightly reduced morale susceptibility).
//
// The "first round only" stun immunity is the key flavor. The Cinderwarden
// isn't a walking fortress — they're a soldier whose training specifically
// covered the moment the fight opens. After the first round they're as
// stunnable as anyone.
this.vigilwalker_trait <- ::inherit("scripts/skills/traits/character_trait", {
	m = {},

	function create()
	{
		character_trait.create();
		m.ID          = "trait.vigilwalker";
		m.Name        = "Vigilwalker";
		m.Icon = "ui/perks/guided_steps_circle.png";  // vanilla fallback
		m.Description = "Trained from the first week of the order — patience, then the spear, then the lantern. A Vigilwalker cannot be ambushed, and the first blow of a battle cannot stagger them.";
		m.Type        = m.Type | ::Const.SkillType.Trait;
	}

	// First-round stun/daze immunity is checked against the tactical round
	// counter. `::Tactical.TurnSequenceBar.m.Round` is the canonical read;
	// falls back safely if it's not populated yet.
	function onUpdate(_properties)
	{
		// Quiet bearing: -15% morale susceptibility. Not immunity — the
		// Cinderwarden can still be moved by a truly bad day, just less
		// readily than the baseline.
		_properties.MoraleEffectMult *= 0.85;

		// First-round stun / daze immunity. v2.0.12 — guard the m.Round
		// field access; during combat-init it can be unset and the throw
		// cascades through MSU's skill_container.update + tactical_doctrine
		// + violet hooks, soft-hanging combat. The "Round" field is set
		// after onCombatStarted of all skills runs, so an early read here
		// is the failure path we silently skip.
		if (::Tactical != null && ::Tactical.isActive()
			&& ::Tactical.TurnSequenceBar != null
			&& ("Round" in ::Tactical.TurnSequenceBar.m))
		{
			local round = ::Tactical.TurnSequenceBar.m.Round;
			if (round <= 1) {
				_properties.IsImmuneToStun = true;
				_properties.IsImmuneToDaze = true;
			}
		}
	}

	// Anti-surprise: at combat start, force the actor out of any "Waiting"
	// state so they get a proper first-round turn. Implemented via
	// onCombatStarted — BB's combat-init order calls every skill's
	// onCombatStarted before the first round's onTurnStart.
	function onCombatStarted()
	{
		character_trait.onCombatStarted();
		local actor = this.getContainer().getActor();
		if (actor == null) return;
		// Surprise-round marker — if BB marked the actor as surprised
		// (IsWaitingForRound), clear it so their full turn is available.
		// The field name varies between BB versions — try the canonical
		// Legends field first and gracefully no-op if it isn't there.
		try {
			if ("IsWaitingForRound" in actor.m && actor.m.IsWaitingForRound) {
				actor.m.IsWaitingForRound = false;
			}
		} catch (e) {}
	}
});
