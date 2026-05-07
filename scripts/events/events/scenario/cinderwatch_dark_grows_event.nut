// Atmospheric event — "The Dark Grows" (~Day 280).
//
// Fires once between the Approach (Beat 2, Day 250) and the Reckoning
// (Beat 3, Day 310). Pure mood-setter — no choice, no mechanical gate —
// just a scene that communicates the world is genuinely darker as the
// company closes on the tower. Tone contrast: Beat 2 was an engagement,
// the Reckoning will be a confrontation; this beat is the quiet between.
this.cinderwatch_dark_grows_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_dark_grows";
		this.m.Title    = "The Dark Grows";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_159.png[/img]"
				+ "{The last morning of the week before the tower, you wake "
				+ "before the wanderer has called your shift. You have slept "
				+ "poorly for three nights. Something outside the camp is "
				+ "doing the thing where it is not quite there — you have "
				+ "seen this before, in the plague year, and you know it "
				+ "does not help to look for it.\n\n"
				+ "The recordkeeper has not slept at all. They are writing "
				+ "by the lantern when you come out of your tent; their eyes "
				+ "have the strained quality of someone who has been trying "
				+ "to remember exactly when a fever started.\n\n"
				+ "'The colours are off,' they say, without looking up.\n\n"
				+ "You did not notice until they said it. Now that they have "
				+ "said it: the dawn is the wrong shade of grey. The grass "
				+ "is darker than grass should be. A crow on a fence-post is "
				+ "watching you and you cannot see its eye because where the "
				+ "eye should be is just an absence.\n\n"
				+ "The lantern burns at the centre of the camp. The ember "
				+ "does not know that the dark is thicker. The ember just "
				+ "burns. You put your hand near it and feel the warmth.\n\n"
				+ "You are close to something. Tomorrow or the day after, "
				+ "you will arrive. You want this to happen and you do not "
				+ "want it to happen and neither of those feelings is doing "
				+ "the other any good.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Break camp. Keep moving.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// Pure mood beat. Small Resolve check flavor; no stat
				// change. Record the beat so brothers' dialogue can
				// reference "we felt it the morning of the crow" in any
				// future hook.
				// v2.0.2: per-brother try/catch. One misbehaving roster
				// entity can't abort the whole mood loop and leave the
				// event in a half-finished state (same bug pattern that
				// caused the Road Shrine LIGHT-branch loop).
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(-0.5, "Something about the road doesn't feel right. The ember burns anyway."); } catch (e) {}
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
		if (::World.getTime().Days < 270) return false;
		if (::World.getTime().Days > 305) return false;
		if (::World.Flags.get("CinderwatchApproachComplete") != true) return false;
		if (::World.Flags.get("CinderwatchDarkGrowsSeen") == true) return false;
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
		try { ::World.Flags.set("CinderwatchDarkGrowsSeen", true); } catch (e) {}
	}
});
