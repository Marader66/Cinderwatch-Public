// Western Tower questline — Beat 1: The Rumor.
//
// Fires once at Day ≥ 150 if:
//   - the scenario is Cinderwatch
//   - the Day-70 Messenger event has already fired (world flag
//     `CinderwatchMessengerReturned` set by
//     `cinderwatch_messenger_event.nut:onFinish`)
//   - this event hasn't fired (`CinderwatchWesternRumorHeard` unset)
//
// Narrative: confirms the silver-ring figure is alive, travelling with the
// Flesh Menders. A name surfaces — someone the Cinderwarden KNEW. A brother
// or sister of the order, long thought dead to the plague. Points west.
//
// Sets `CinderwatchWesternRumorHeard = true` on finish, which Beat 2
// (Approach, Day 250) gates on.
this.cinderwatch_western_rumor_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_western_rumor";
		this.m.Title    = "A Name From the Watch";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		// Screen A — the traveller's tale
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_36.png[/img]"
				+ "{A cartwright at a waypoint recognises your lantern. "
				+ "He has been waiting. Since some while, he says — perhaps "
				+ "you were meant to come by, perhaps not. He has a story he "
				+ "has told nobody because he does not know who to tell.\n\n"
				+ "He has seen the silver ring the messenger described. Not "
				+ "once — twice, in the last month, on a traveller who came "
				+ "east along the western road, wearing grey and moving in "
				+ "the company of the kind of people nobody mentions by name. "
				+ "Flesh Menders, he says, looking at his boots.\n\n"
				+ "The traveller had a face he half-knew. He could not place "
				+ "it until he saw the ring. Then he placed it and wished he "
				+ "had not.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Whose face was it?",
				function getResult(_event) { return "B"; }
			}],
			function start(_event) {}
		});

		// Screen B — the name
		this.m.Screens.push({
			ID   = "B",
			Text = "{The cartwright tells you the name. He tells you quietly "
				+ "and he tells you only once.\n\n"
				+ "You stand for a long time at the waypoint. The name "
				+ "belonged to someone you buried — or thought you buried — "
				+ "in the worst week of the plague year. The order mourned "
				+ "them. You wrote the name in the watch-log with your own "
				+ "hand. You remember the hand shaking.\n\n"
				+ "They lived. They lived and left. They lived and came back, "
				+ "and when they came back they extinguished the western "
				+ "ember — their own ember, the one they had tended with "
				+ "you when you were both apprentices, when they still "
				+ "laughed at the old jokes.\n\n"
				+ "You do not know yet what you will do when you find them. "
				+ "You know only that you will find them.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Thank him. Ride west.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// Morale dip across the company — this is a bad discovery.
				// v2.0.2: per-brother try/catch guard.
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(-1.0, "A name the Cinderwarden thought was dead. Alive. On the wrong road."); } catch (e) {}
					}
				} catch (e) {}
				// Small renown bump — word of the Cinderwarden's westward
				// purpose spreads along the waypoint circuit.
				try { ::World.Assets.addBusinessReputation(15); } catch (e) {}
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
		if (::World.getTime().Days < 150) return false;
		if (::World.Flags.get("CinderwatchMessengerReturned") != true) return false;
		if (::World.Flags.get("CinderwatchWesternRumorHeard") == true) return false;
		return true;
	}

	function onUpdateScore()
	{
		this.m.Score = 0;
		if (!this.isValid()) return;
		this.m.Score = 80;
	}

	function onFinish()
	{
		try { ::World.Flags.set("CinderwatchWesternRumorHeard", true); } catch (e) {}
	}
});
