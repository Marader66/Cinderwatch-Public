// cinderwatch_messenger_event — atmospheric late-campaign event.
//
// Fires once at Day ≥ 70 in the Cinderwatch scenario, as the company nears
// the western reaches. The messenger from the intro returns with additional
// information about the western tower — enough to hint at a specific culprit
// without locking in a resolution (that's a v2.0 questline if I get to it).
//
// Flavor-only: small gold payout (the messenger was paid to find you),
// small renown, and a mood bump for the company. Sets the
// `CinderwatchWesternTowerRumored` world flag for any future questline to
// gate on.
this.cinderwatch_messenger_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_messenger";
		this.m.Title    = "A Messenger Returns";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		// Screen A — the messenger catches up
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_36.png[/img]"
				+ "{You hear him before you see him — a horse at a canter on "
				+ "the road behind you, too fast for this time of day. You turn "
				+ "and wait.\n\n"
				+ "It is the messenger. The same one who rode up to the "
				+ "Cinderwatch in the rain. His horse is not the same horse — "
				+ "that one, he tells you later, is recovering at a mill. The "
				+ "one under him now is smaller and stubborn and it has got "
				+ "him this far.\n\n"
				+ "He has been looking for you for a month. He has a name.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Tell it to me.",
				function getResult(_event) { return "B"; }
			}],
			function start(_event) {}
		});

		// Screen B — the name
		this.m.Screens.push({
			ID   = "B",
			Text = "{He does not know exactly what happened at the western "
				+ "tower. He is not a brother of the order. But he has talked "
				+ "to people who were there in the days before the ember died, "
				+ "and one of them, a cheese-seller's daughter who had been "
				+ "bringing the tower its weekly supply, told him a story.\n\n"
				+ "Someone came to the tower in the last week of the order's "
				+ "last winter. He wore the grey of a priest or a magistrate "
				+ "— she was not sure which, and it is hard to tell in these "
				+ "lean years. He stayed three nights. He asked to stand watch "
				+ "with the last sister of the order. She said yes, because "
				+ "she had been alone for a long time. The next morning she "
				+ "was dead and he was gone and the ember had gone out.\n\n"
				+ "The messenger does not know the man's name. But the "
				+ "cheese-seller's daughter remembers a ring: silver, with a "
				+ "mark like a closed eye.\n\n"
				+ "'I have not seen that mark before,' the messenger says. "
				+ "'I thought you might have.'}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "I have seen it. Thank you.",
				function getResult(_event) { return "C"; }
			}, {
				Text = "I have not. But I will remember the mark.",
				function getResult(_event) { return "C"; }
			}],
			function start(_event) {}
		});

		// Screen C — departure
		this.m.Screens.push({
			ID   = "C",
			Text = "{You pay the messenger. You pay him twice what he expects "
				+ "and he tries to give half back — he says the news was worth "
				+ "less than that, and anyway the order used to feed him in "
				+ "bad years when he was a boy. You tell him to keep it. He "
				+ "keeps it.\n\n"
				+ "You ride west. The company, which has been quietly curious "
				+ "about the messenger, is now quietly thoughtful. The "
				+ "recordkeeper opens their book and writes in it for a long "
				+ "time at the first stop.\n\n"
				+ "A silver ring. A closed eye. You will know it when you see "
				+ "it.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "We ride.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				try {
					::World.Assets.addMoney(-40);         // paid the messenger
					::World.Assets.addBusinessReputation(25);  // your bearing spreads
				} catch (e) {}
				// v2.0.2: per-brother try/catch guard.
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(2.0, "A messenger brought news of the western tower. There is a name on the wind now."); } catch (e) {}
					}
				} catch (e) {}
			}
		});
	}

	// v2.2.1: isValid() is the gate BB calls for special-pool events. Without it,
	// addSpecialEvent fires the event every tick regardless of onUpdateScore's
	// flag check. Same trap GT Partner Quest hit at v2.6.11.
	function isValid()
	{
		if (::World == null) return false;
		local scenarioID = "";
		try { scenarioID = ::World.Assets.getOrigin().getID(); } catch (e) { return false; }
		local scenarioOK = (scenarioID == "scenario.cinderwatch") || (scenarioID == "scenario.three_musketeers")
			|| (scenarioID == "scenario.golden_throne" && ::Cinderwatch._hasCinderwardenInRoster());
		if (!scenarioOK) return false;
		if (::World.getTime().Days < 70) return false;
		if (::World.Flags.get("CinderwatchMessengerReturned") == true) return false;
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
		try {
			::World.Flags.set("CinderwatchMessengerReturned", true);
			// Flag is read by a hypothetical future questline; harmless if unused.
			::World.Flags.set("CinderwatchWesternTowerRumored", true);
		} catch (e) {}
	}
});
