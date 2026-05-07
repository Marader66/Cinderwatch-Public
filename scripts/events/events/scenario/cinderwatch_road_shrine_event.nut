// cinderwatch_road_shrine_event — atmospheric mid-campaign event.
//
// Fires once at Day ≥ 15 in the Cinderwatch scenario. Flavor-only: no combat,
// no mechanical progression, just a small mood/gold choice that makes the
// journey feel lived-in and reinforces the lantern/watching theme.
//
// Fires once (guarded by `CinderwatchRoadShrineSeen` world flag).
this.cinderwatch_road_shrine_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_road_shrine";
		this.m.Title    = "The Road Shrine";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		// Screen A — the find
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_130.png[/img]"
				+ "{You stop at a wayside shrine an hour before sunset. It is "
				+ "small — two waist-high stone pillars and a soot-stained "
				+ "alcove between them, the kind of shrine a farming village "
				+ "keeps because somebody's grandmother did. The alcove is "
				+ "meant to hold a lantern or a candle.\n\n"
				+ "It is empty. But the alcove has been swept recently. There "
				+ "is fresh wax on the stone.\n\n"
				+ "Someone has been keeping the shrine, even without a flame "
				+ "to put in it. You cannot tell whether that should make you "
				+ "feel better or worse.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [
				{
					Text = "Leave a coin and a measure of oil. The caretaker can finish the work.",
					function getResult(_event) { return "GIFT"; }
				},
				{
					Text = "Open the lantern and light it myself. The shrine will have a flame tonight.",
					function getResult(_event) { return "LIGHT"; }
				},
				{
					Text = "We have our own road. Ride on.",
					function getResult(_event) { return "PASS"; }
				}
			],
			function start(_event) {}
		});

		// Option 1 — the gift. Small gold cost, good mood.
		this.m.Screens.push({
			ID   = "GIFT",
			Text = "{You leave a small leather pouch in the alcove. Inside: "
				+ "a silver coin, a thimble of lamp oil, a stub of beeswax "
				+ "candle from your own pack. The quartermaster nods when you "
				+ "come back to the horses. The recordkeeper is writing "
				+ "something in the margin of their book.\n\n"
				+ "You ride on. The company is a little quieter than they were, "
				+ "and a little closer to each other. You have done the small "
				+ "thing. That is always worth doing.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Ride on.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// v2.0.2: set once-flag BEFORE any throwable ops, so even
				// if a mood-update or asset-write later throws, the event
				// can never re-fire. Previously relied on onFinish which
				// doesn't run if start() throws midway.
				try { ::World.Flags.set("CinderwatchRoadShrineSeen", true); } catch (e) {}
				try { ::World.Assets.addMoney(-30); } catch (e) {}
				try { ::World.Assets.addBusinessReputation(10); } catch (e) {}
				// Per-brother try/catch — one misbehaving entity can't
				// abort the whole mood loop (a wounded / null-state /
				// transient-off-field brother sometimes throws in
				// improveMood and the old unguarded foreach would bail
				// out mid-iteration).
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(1.5, "The Cinderwarden kept a small promise at a wayside shrine."); } catch (e) {}
					}
				} catch (e) {}
			}
		});

		// Option 2 — light it yourself. Mood boost, small renown, costs a bit of oil.
		this.m.Screens.push({
			ID   = "LIGHT",
			Text = "{You open the brass lantern just long enough to touch a "
				+ "borrowed wick to the ember. The wick catches. You set it in "
				+ "the shrine's alcove, close the shutter against the wind.\n\n"
				+ "The wanderer who winters with you watches this without "
				+ "speaking. The recordkeeper is smiling the small smile they "
				+ "sometimes smile. When you mount up and ride the shrine is "
				+ "already a yellow dot behind you, the only yellow for a mile "
				+ "of road.\n\n"
				+ "Someone, tomorrow, will walk this path and see a shrine "
				+ "that burns. They will not know who did that. The order did "
				+ "not care who knew.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "The light travels. So does the company.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// v2.0.2: THIS is the branch the user hit — "Lighting of a
				// candle" prompt that looped. Setting the flag first, then
				// guarding each throwable in turn, prevents any combination
				// of roster-state edge cases from aborting the event
				// mid-start and re-queuing it.
				try { ::World.Flags.set("CinderwatchRoadShrineSeen", true); } catch (e) {}
				try { ::World.Assets.addBusinessReputation(20); } catch (e) {}
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(3.0, "The Cinderwarden set a flame in a wayside shrine."); } catch (e) {}
					}
				} catch (e) {}
			}
		});

		// Option 3 — pass. No mood change, no cost. The road is long.
		this.m.Screens.push({
			ID   = "PASS",
			Text = "{You ride past. The shrine recedes. You do not look back "
				+ "at it — the western tower is the road, and the shrine is "
				+ "not. The wanderer says nothing. The recordkeeper says "
				+ "nothing. The quartermaster says nothing, specifically.\n\n"
				+ "It is a long evening and no one sings at the camp.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "On.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// v2.0.2: even the no-op PASS branch now sets the flag.
				// Defensive uniformity — every branch ends in a known
				// "seen" state, regardless of what path the player took.
				try { ::World.Flags.set("CinderwatchRoadShrineSeen", true); } catch (e) {}
			}
		});
	}

	// v2.2.1: isValid() is the gate BB calls for special-pool events. Without it,
	// addSpecialEvent fires the event every tick regardless of onUpdateScore's
	// flag check. Same trap GT Partner Quest hit at v2.6.11 — see
	// reference_bb_special_events_isvalid memory rule.
	function isValid()
	{
		if (::World == null) return false;
		local scenarioID = "";
		try { scenarioID = ::World.Assets.getOrigin().getID(); } catch (e) { return false; }
		local scenarioOK = (scenarioID == "scenario.cinderwatch") || (scenarioID == "scenario.three_musketeers")
			|| (scenarioID == "scenario.golden_throne" && ::Cinderwatch._hasCinderwardenInRoster());
		if (!scenarioOK) return false;
		if (::World.getTime().Days < 15) return false;
		if (::World.Flags.get("CinderwatchRoadShrineSeen") == true) return false;
		return true;
	}

	function onUpdateScore()
	{
		this.m.Score = 0;
		if (!this.isValid()) return;
		this.m.Score = 50;
	}

	// onFinish is a belt-and-suspenders — the flag is now set from each
	// terminal-option screen's start() in v2.0.2 (above), but we still set
	// it here too in case BB's lifecycle order ever changes and start()
	// fires before the flag-set.
	function onFinish()
	{
		try { ::World.Flags.set("CinderwatchRoadShrineSeen", true); } catch (e) {}
	}
});
