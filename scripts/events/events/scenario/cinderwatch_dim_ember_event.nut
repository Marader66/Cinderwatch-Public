// Atmospheric event — "A Dim Ember" (~Day 180).
//
// Fires once after the Western Rumor (Beat 1) and before the Approach
// (Beat 2). Flavor-only: the Cinderwarden's lantern needs oil; player
// chooses how to address it. No mechanical gate on Beat 2 — the choice
// affects mood and a small gold/renown delta, nothing more.
//
// Scheduled between Beat 1 (Day 150) and Beat 2 (Day 250), so the
// trigger window is Day 170-240. Fires first time eligible.
this.cinderwatch_dim_ember_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_dim_ember";
		this.m.Title    = "A Dim Ember";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		// Screen A — the problem
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_06.png[/img]"
				+ "{The lantern is dim. You noticed it last night at the fire "
				+ "and you were hoping you were wrong, but you are not wrong. "
				+ "The ember is the same colour as always — a small orange "
				+ "seed — but the light it throws has been shrinking for a "
				+ "week and you cannot convince yourself otherwise.\n\n"
				+ "It is the oil. You are running low on the order's oil, "
				+ "the specific kind distilled at the watchtower before the "
				+ "plague. You can make it stretch with regular lamp-oil from "
				+ "any waypoint — the ember will not care about the "
				+ "difference in purity — but it will cost coin to keep the "
				+ "flame bright along the road to the west.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [
				{
					Text = "Pay for the best oil a merchant can give us. The ember stays bright.",
					function getResult(_event) { return "BRIGHT"; }
				},
				{
					Text = "Settle for what we can afford. Dim is better than dark.",
					function getResult(_event) { return "DIM"; }
				},
				{
					Text = "Let it gutter. The light we carry is not in the oil.",
					function getResult(_event) { return "GUTTER"; }
				}
			],
			function start(_event) {}
		});

		// BRIGHT — spend the gold, preserve the ember.
		this.m.Screens.push({
			ID   = "BRIGHT",
			Text = "{You spend what it costs. The quartermaster does not "
				+ "argue with you about it. He argues with you about most "
				+ "other expenses but not this one; he knew what you would "
				+ "choose before you chose.\n\n"
				+ "The company sleeps easier for the rest of the week. The "
				+ "lantern's light reaches the picket lines the way it is "
				+ "supposed to. You do not let yourself think about how "
				+ "you would feel if you had chosen otherwise.}",
			Image      = "", Banner = "", List = [], Characters = [],
			Options = [{ Text = "The light holds.", function getResult(_event) { return 0; } }],
			function start(_event)
			{
				try { ::World.Assets.addMoney(-150); } catch (e) {}
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(2.5, "The Cinderwarden paid for proper oil. The lantern burns bright."); } catch (e) {}
					}
				} catch (e) {}
			}
		});

		// DIM — middle road.
		this.m.Screens.push({
			ID   = "DIM",
			Text = "{You buy the cheaper oil. The ember accepts it, because "
				+ "the ember has accepted worse — the order ran on what it "
				+ "could get, most years — but the light is smaller now, "
				+ "and you can tell at the cook-fire that the company has "
				+ "noticed. Nobody says anything. You do not say anything "
				+ "about them noticing.\n\n"
				+ "The road west has one fewer promises in it than it did "
				+ "last week. That is a thing that can be lived with. You "
				+ "will live with it.}",
			Image      = "", Banner = "", List = [], Characters = [],
			Options = [{ Text = "Dim is better than dark.", function getResult(_event) { return 0; } }],
			function start(_event)
			{
				try { ::World.Assets.addMoney(-40); } catch (e) {}
				try { ::World.Flags.set("CinderwatchEmberDimmed", true); } catch (e) {}
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(-0.5, "The lantern burns smaller than it should."); } catch (e) {}
					}
				} catch (e) {}
			}
		});

		// GUTTER — no cost, big mood hit.
		this.m.Screens.push({
			ID   = "GUTTER",
			Text = "{You let the ember do what it does. It dims to nearly "
				+ "nothing — a small red point at the heart of the brass, "
				+ "the way it is when the wind gets under the door and the "
				+ "order is mostly asleep and nobody is supposed to be "
				+ "looking. You have seen it look like this before. You "
				+ "have not seen it look like this on the road.\n\n"
				+ "The company rides through a day that feels darker than "
				+ "the sky it's under. The quartermaster is tight-lipped. "
				+ "The recordkeeper does not write anything that night. "
				+ "When you check the lantern in the morning it is still "
				+ "alive — barely — and you understand, in a way you did "
				+ "not understand yesterday, what it would mean to carry "
				+ "it to the west dead.}",
			Image      = "", Banner = "", List = [], Characters = [],
			Options = [{ Text = "It is alive. That is still enough.", function getResult(_event) { return 0; } }],
			function start(_event)
			{
				try { ::World.Flags.set("CinderwatchEmberDimmed", true); } catch (e) {}
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(-2.0, "The Cinderwarden let the ember gutter. The dark feels closer."); } catch (e) {}
					}
				} catch (e) {}
			}
		});
	}

	function isValid()
	{
		if (::World == null) return false;
		local scenarioID = "";
		try { scenarioID = ::World.Assets.getOrigin().getID(); } catch (e) { return false; }
		local scenarioOK = (scenarioID == "scenario.cinderwatch") || (scenarioID == "scenario.three_musketeers")
			|| (scenarioID == "scenario.golden_throne" && ::Cinderwatch._hasCinderwardenInRoster());
		if (!scenarioOK) return false;
		if (::World.getTime().Days < 170) return false;
		if (::World.getTime().Days > 240) return false;
		if (::World.Flags.get("CinderwatchDimEmberSeen") == true) return false;
		if (::World.Flags.get("CinderwatchWesternRumorHeard") != true) return false;
		return true;
	}

	function onUpdateScore()
	{
		this.m.Score = 0;
		if (!this.isValid()) return;
		this.m.Score = 60;
	}

	function onFinish()
	{
		try { ::World.Flags.set("CinderwatchDimEmberSeen", true); } catch (e) {}
	}
});
