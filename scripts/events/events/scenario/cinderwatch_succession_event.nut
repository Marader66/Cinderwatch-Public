// "The Lantern Passes." — v2.5.0 succession event.
//
// Fires the first world-map tick after the Cinderwarden has died at Watch
// Tier IV (150+ Watch Points) and `cinderwarden_trait.onDeath` has handed
// off the title to the nearest sworn ally. The trait sets
// `CinderwatchInheritorPending` + `CinderwatchInheritorName` for this
// event to read. One-shot per campaign — `CinderwatchSuccessionShown`
// flag prevents re-firing on the same save.
//
// Tone: quiet, matter-of-fact. The order's first lesson was that the
// ember does not need a particular hand. The body of the warden being
// gone is grief; the body of the watch being gone is not what happened.
this.cinderwatch_succession_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_succession";
		this.m.Title    = "The Lantern Passes";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_159.png[/img]"
				+ "{The Cinderwarden is dead.\n\n"
				+ "It is the kind of death the order trained for and the "
				+ "kind it never expected. There was no failing. There was "
				+ "an arrow, or a blade, or a bad step — the small thing "
				+ "that ends a long watch.\n\n"
				+ "The brass lantern is still warm when %inheritorname% "
				+ "lifts it. The ember inside is the same ember it was "
				+ "this morning. The order taught, in the long evenings "
				+ "before the plague, that the ember does not know whose "
				+ "hand carries it. The ember just burns.\n\n"
				+ "%inheritorname% does not say anything. There is nothing "
				+ "to say. The company is watching. The wind is moving "
				+ "across the camp. Somewhere out there is whatever it was "
				+ "the warden saw last.\n\n"
				+ "%inheritorname%'s shift starts at sundown. The watch "
				+ "continues.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Take up the lantern. The watch continues.",
				function getResult(_event) { return 0; }
			}]
		});
	}

	function onPrepare()
	{
		// Substitute %inheritorname% across all screen Text fields. Done
		// in onPrepare per the v2.6.8 GT lesson (don't do dynamic Text
		// substitution in screen `start()` via _event.Text — only m.Screens
		// dicts have Text; the parent event doesn't).
		local name = "the new warden";
		try {
			local stored = ::World.Flags.getAsString("CinderwatchInheritorName");
			if (stored != "") name = stored;
		} catch (e) {}

		foreach (screen in this.m.Screens) {
			if ("Text" in screen) {
				screen.Text = ::MSU.String.replace(screen.Text, "%inheritorname%", name);
			}
		}
	}

	function isValid()
	{
		if (::World == null) return false;
		local scenarioID = "";
		try { scenarioID = ::World.Assets.getOrigin().getID(); } catch (e) { return false; }
		local scenarioOK = (scenarioID == "scenario.cinderwatch")
			|| (scenarioID == "scenario.three_musketeers")
			|| (scenarioID == "scenario.golden_throne" && ::Cinderwatch._hasCinderwardenInRoster());
		if (!scenarioOK) return false;
		if (::World.Flags.get("CinderwatchInheritorPending") != true) return false;
		if (::World.Flags.get("CinderwatchSuccessionShown") == true) return false;
		return true;
	}

	function onUpdateScore()
	{
		this.m.Score = 0;
		if (!this.isValid()) return;
		// High score so this fires before any ambient mood event the same
		// tick. The succession is the load-bearing narrative beat after
		// the warden dies.
		this.m.Score = 200;
	}

	function onFinish()
	{
		try { ::World.Flags.set("CinderwatchSuccessionShown", true); } catch (e) {}
		try { ::World.Flags.set("CinderwatchInheritorPending", false); } catch (e) {}
	}
});
