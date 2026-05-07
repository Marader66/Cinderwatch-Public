// cinderwatch_intro_event — 4-screen narrative intro that sets the tone and
// surfaces the mechanical identity (Long Watch, Ember of Watch, Warden's
// Promise) in the closing-info screen.
//
// Tone notes:
//   - Grounded and tired, not heroic.
//   - The Cinderwarden is old and a bit shabby; the order died of plague.
//   - The inciting event (twin tower's ember gone dark) is understated — no
//     apocalyptic fanfare, just a messenger and a bad letter.
//   - The final screen ("The Road") should read as the player accepting a
//     job, not being chosen by fate.
this.cinderwatch_intro_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.cinderwatch_intro";
		this.m.IsSpecial = true;

		// ── Screen GENDER: Player-facing gender choice (v1.2.0) ─────────────
		// Fires before the narrative proper. The Cinderwarden's title stays
		// gender-neutral ("The Cinderwarden" in both cases) — the choice
		// affects actor.m.Gender (pronouns, gender-aware rolls) and sets
		// `CinderwardenIsFemale` as a world flag for future code branches.
		//
		// Soft choice: the body sprite was rolled at spawn time from
		// Bodies.AllMale and doesn't get swapped post-hoc (BB's sprite
		// layer system doesn't expose a clean gender-swap API for a
		// fully-instantiated actor). A v2+ update could expose Bodies
		// via MSU mod setting, set BEFORE character creation, which would
		// drive the sprite roll as well.
		this.m.Screens.push({
			ID   = "GENDER",
			Text = "[img]gfx/ui/events/event_06.png[/img]"
				+ "{Before the messenger. Before the letter. Before the long "
				+ "plague-years and the shape the order took as it thinned.\n\n"
				+ "A small thing. The world asks: who are you, that stands "
				+ "watch?}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [
				{
					Text = "A man of the Cinderwatch.",
					function getResult(_event) { return "A"; }
				},
				{
					Text = "A woman of the Cinderwatch.",
					function getResult(_event)
					{
						_event.setOriginGender(true);
						return "A";
					}
				}
			],
			function start(_event) {}
		});

		// ── Screen A: The Letter ───────────────────────────────────────────
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_06.png[/img]"
				+ "{A rider came to the tower three days ago. You saw him from the "
				+ "wall — a poor messenger in poor weather, on a horse that had "
				+ "nearly run itself to death. You went down to meet him yourself. "
				+ "There was no one else left to go.\n\n"
				+ "He carried a letter stamped with a seal you had not seen in "
				+ "twenty years. The western tower's seal. You read it standing in "
				+ "the rain, and when you had read it, you read it again, more "
				+ "slowly.\n\n"
				+ "The ember at the western watch has gone out. Not dimmed — "
				+ "out. The writer — someone's clerk, from the signature, not "
				+ "any brother or sister of the order you would have known — "
				+ "writes that the cause is 'uncertain', which you understand "
				+ "to mean 'deliberately unexamined'.\n\n"
				+ "You stand a long time in the rain.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options    = [{
				Text = "I read it again.",
				function getResult(_event) { return "B"; }
			}],
			function start(_event) {}
		});

		// ── Screen B: The Tower ────────────────────────────────────────────
		this.m.Screens.push({
			ID   = "B",
			Text = "[img]gfx/ui/events/event_29.png[/img]"
				+ "{The Cinderwatch has been yours alone for eleven years. "
				+ "There used to be twenty-nine of you. Then nineteen. Then seven. "
				+ "Then two, for a long stretch that was the hardest part — "
				+ "you and Old Karel, who had been the order's archivist, and "
				+ "then only you, after the morning you found him at his desk "
				+ "with the page he had been copying still wet.\n\n"
				+ "The tower's ember you have kept since. It has never gone out. "
				+ "You have slept in the watch room for a decade so that if the "
				+ "wind turned bad you would wake to tend it.\n\n"
				+ "You look at the ember now. Steady. A little orange seed in its "
				+ "iron bowl. You think of the other tower and whose hands let "
				+ "the other ember die. You find that you are not surprised to "
				+ "be thinking of leaving.\n\n"
				+ "The quartermaster is saddling horses without being asked. "
				+ "The recordkeeper has pulled the watch-logs out of their chest. "
				+ "The wandering knight who wintered with you last year is still "
				+ "here, it turns out — they never left. You hadn't noticed.\n\n"
				+ "Three people. One lantern. A road.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options    = [{
				Text = "We ride west.",
				function getResult(_event) { return "C"; }
			}],
			function start(_event) {}
		});

		// ── Screen C: The Promise ──────────────────────────────────────────
		this.m.Screens.push({
			ID   = "C",
			Text = "[img]gfx/ui/events/event_159.png[/img]"
				+ "{Before you leave you do the thing the order always did when "
				+ "it sent a watcher abroad. You stand in the watch room with the "
				+ "other three and you say the short old promise: to keep the "
				+ "light while the light can be kept. That's the whole of it. "
				+ "The order was plain.\n\n"
				+ "The quartermaster says it with the dry clip of someone who has "
				+ "said it a hundred times. The recordkeeper's voice breaks a "
				+ "little — they have not spoken it since their novitiate. The "
				+ "knight says it last, and seems surprised by the sound of their "
				+ "own voice speaking it.\n\n"
				+ "You take the ember out of its iron bowl. You put it in the "
				+ "brass lantern you carry on the road. You close the lantern's "
				+ "little door.\n\n"
				+ "The watch room is dark for the first time in your life.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options    = [{
				Text = "The light travels with me now.",
				function getResult(_event) { return "D"; }
			}],
			function start(_event) {}
		});

		// ── Screen D: The Brief ────────────────────────────────────────────
		// Mechanical summary. Written to match the character's voice — a
		// practical warden ticking off what the player needs to know.
		this.m.Screens.push({
			ID   = "D",
			Text = "[img]gfx/ui/events/event_73.png[/img]"
				+ "{[color=#E07A3A]The Cinderwatch — Scenario Details[/color]\n\n"
				+ "[color=#bcad8c]The Cinderwarden:[/color] Moderate warrior stats, 3-star Resolve "
				+ "and Fatigue talents, no divine protection. A disciplined old soldier "
				+ "with a lantern. Starts with a billhook and a brass lantern trinket.\n\n"
				+ "[color=#bcad8c]Vigilwalker:[/color] The order's training — cannot be surprised, "
				+ "immune to stun and daze on the first round of any combat. After that, "
				+ "as vulnerable as anyone.\n\n"
				+ "[color=#bcad8c]Ember of the Watch:[/color] A small 4-tile personal aura. "
				+ "Allies within it gain +5 Resolve and +2 Fatigue Recovery. "
				+ "No enemy-side effect — this lantern warms only those who ask.\n\n"
				+ "[color=#bcad8c]Rekindle:[/color] Once per battle, share the ember. "
				+ "Restores 30 Fatigue to the Cinderwarden and every ally within 3 tiles, "
				+ "and leaves them breathing easier for two turns.\n\n"
				+ "[color=#bcad8c]The Long Watch:[/color] At each turn start, if the Cinderwarden "
				+ "is 4 or more tiles from any ally, they earn a Watch Point. Tier unlocks "
				+ "at 10 / 30 / 75 / 150: a stat bump, the Lantern Strike active skill, "
				+ "a permanent aura expansion, and — if the warden falls at Tier IV — "
				+ "the ember passes to the nearest ally.\n\n"
				+ "[color=#bcad8c]Warden's Promise:[/color] Every hire takes the order's "
				+ "short oath. +5 Resolve. Cannot rout while the Cinderwarden lives and "
				+ "fights. The company coheres around you; hold.\n\n"
				+ "[color=#bcad8c]Objective:[/color] Reach the western tower. "
				+ "Find out what happened to its ember. Rekindle what can be rekindled.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options    = [{
				Text = "The road is long. We ride.",
				function getResult(_event) { return 0; }
			}],
			function start(_event) {}
		});
	}

	// v2.0.1 defensive: explicit zero-score. BB's event-pool scoring default
	// varies between versions; setting m.Score = 0 here makes absolutely
	// sure the intro is never picked up by the special-event scoring pool.
	// Also check our once-flag — if the intro has already been seen, block
	// any re-fire attempt from any path (scheduleEvent, replay, save-load
	// timing weirdness).
	function onUpdateScore()
	{
		this.m.Score = 0;
		if (::World != null && ::World.Flags.get("CinderwatchIntroSeen") == true) {
			this.m.Score = 0;  // defensive no-op; flag's the real gate
		}
	}

	function onPrepare()
	{
		this.m.Title = "The Cinderwatch — An Old Letter";
	}

	function onPrepareVariables(_vars) {}
	function onClear()           {}

	function onDetermineStartScreen()
	{
		return "GENDER";
	}

	// v2.0.1 defensive: once-flag. Set on onFinish so the intro can never
	// replay. `scenario.onSpawnPlayer` now also checks this flag before
	// firing (see cinderwatch_scenario.onSpawnPlayer).
	function onFinish()
	{
		try { ::World.Flags.set("CinderwatchIntroSeen", true); } catch (e) {}
	}

	// Post-hoc gender flip (v1.2.0). See comment on GENDER screen for the
	// design caveat. The Cinderwarden title stays "The Cinderwarden" in both
	// cases — the order didn't gender-mark its titles — so we change
	// actor.m.Gender and set the world flag, no rename.
	function setOriginGender(_isFemale)
	{
		if (!_isFemale) return;
		if (::World == null) return;
		local roster = ::World.getPlayerRoster();
		if (roster == null) return;

		local warden = null;
		foreach (bro in roster.getAll()) {
			if (bro == null) continue;
			if (bro.getFlags().get("Cinderwarden")) { warden = bro; break; }
		}
		if (warden == null) return;

		// v2.5.0 — use Legends' setGender(1, true) instead of raw m.Gender=1.
		// setGender re-rolls VoiceSet, Body, Hair into female-valid pools,
		// sets all 5 Sound array slots from WomanSounds, switches Faces /
		// Bodies / Hairs to female equivalents, adjusts SoundPitch /
		// SoundVolume. Same fix Golden Throne v2.7.1 used. Resolves the
		// v1.2.0 caveat where the body sprite stayed male even on Empress
		// branch, and prevents the v2.7.1-style save-load crash where
		// VoiceSet could land on an out-of-range female index.
		try { warden.setGender(1, true); }
		catch (e) {
			::logWarning("[mod_cinderwatch] setGender(1, true) failed: " + e + " — falling back to raw m.Gender=1");
			try { warden.m.Gender = 1; } catch (e2) {}
		}
		try { ::World.Flags.set("CinderwardenIsFemale", true); } catch (e) {}

		::logInfo("[mod_cinderwatch] Origin set to female by intro choice.");
	}
});
