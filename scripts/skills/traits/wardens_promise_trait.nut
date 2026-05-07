// wardens_promise_trait — the company-wide buff granted to every brother
// who joins the Cinderwarden's roster.
//
// Unlike Golden Throne's Mandate / Oath / Chosen three-layer brother system,
// Cinderwatch deliberately uses ONE lightweight trait. This is a design
// choice: the scenario's complexity lives in the origin's Watch Points
// mechanic and the intro-event narrative, not in brother-progression
// systems. The company is a small fellowship around one lantern, and
// that's enough identity.
//
// Effect:
//   - +5 Resolve (always)
//   - Cannot rout while the Cinderwarden is alive and fighting. Implemented
//     via `MoraleEffectMult = 0` when the Cinderwarden is alive; drops to
//     vanilla behavior once the warden falls. This makes the company cohere
//     around the origin character's survival — another identity hook,
//     matching the story's "the last of the order" flavor.
this.wardens_promise_trait <- ::inherit("scripts/skills/traits/character_trait", {
	m = {},

	function create()
	{
		character_trait.create();
		m.ID          = "trait.wardens_promise";
		m.Name        = "Warden's Promise";
		// v1.3.3: swapped from vanilla perk_15 fallback to holyfire_circle
		// — same hand-with-flame icon the Cinderwarden's own trait uses
		// (and the Emperor, Pillar of Light, etc. in Golden Throne). The
		// shared visual says what the fiction says: every sworn brother
		// carries the mark of the watch-fire. The ember passes to each
		// hand that takes the oath.
		m.Icon = "ui/perks/legend_vala_spiritual_bond.png";
		m.Description = "Sworn to keep the watch with the Cinderwarden. While the warden stands, this one will not run.";
		m.Type        = m.Type | ::Const.SkillType.Trait;
	}

	function onUpdate(_properties)
	{
		_properties.Bravery += 5;

		// Morale anchor — only while the Cinderwarden is alive and fighting.
		// Cheap check every onUpdate: iterate the tactical roster. If we're
		// not in tactical, fall back to the world-map roster so the tooltip
		// still reflects the true state.
		if (this._isCinderwardenAlive()) {
			_properties.MoraleEffectMult *= 0.0;

			// v1.3.0 — Night Watch. If the Cinderwarden has reached Long
			// Watch Tier III (75+ Watch Points), the `CinderwatchNightWatch`
			// world flag is set, and the lantern banishes night for the
			// whole company. The Cinderwarden self-applies the same
			// property in their own trait's onUpdate; this branch covers
			// every hired brother.
			if (::World != null && ::World.Flags.get("CinderwatchNightWatch")) {
				_properties.IsAffectedByNight = false;
			}
		}
	}

	function _isCinderwardenAlive()
	{
		// In tactical combat: check actors on the battlefield.
		if (::Tactical != null && ::Tactical.isActive()) {
			local entities = ::Tactical.Entities.getAllInstances();
			if (entities != null) {
				foreach (list in entities) {
					foreach (e in list) {
						if (e == null) continue;
						if (e.getFlags().has("Cinderwarden") && e.isAlive()) {
							return true;
						}
					}
				}
			}
			return false;
		}
		// In the world map: check the player roster.
		if (::World != null) {
			local roster = ::World.getPlayerRoster();
			if (roster != null) {
				foreach (bro in roster.getAll()) {
					if (bro == null) continue;
					if (bro.getFlags().get("Cinderwarden")) return true;
				}
			}
		}
		return false;
	}
});
