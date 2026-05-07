// Western Tower questline — Beat 3: The Reckoning.
//
// Fires once at Day ≥ 310 if Beat 2 (Approach) has landed and the Reckoning
// hasn't fired yet, in scenario.cinderwatch OR scenario.golden_throne when
// a Cinderwarden brother is in the company.
//
// v2.1.0: scripted combat — direct startScriptedCombat from screen B's
// option launches the fight against the Extinguisher. Post-combat,
// `registerToShowAfterCombat` routes to Victory ("D") or Defeat ("DEFEAT")
// screens. The Vigil Censer drops from the Extinguisher's corpse (injected
// via his onDeath) — the player picks it up from the standard combat loot
// UI, not via stash-spawn.
//
// On retreat / defeat, `CinderwatchReckoningComplete` stays unset so the
// event re-scores at the next gate-check (next day) — the player can try
// again.

this.cinderwatch_reckoning_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_reckoning";
		this.m.Title    = "The Dead Tower";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		// Screen A — the tower
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_29.png[/img]"
				+ "{The tower is smaller than you remember. You were last "
				+ "here forty years ago, when you and the one you are about "
				+ "to fight were apprentices together — rope burns on your "
				+ "hands from the bell-pulls, the old mistress of the west "
				+ "watch shouting corrections at you both from the parapet.\n\n"
				+ "The mistress is long dead. The bell is gone. The parapet "
				+ "is half-fallen. The ember-bowl at the top of the tower is "
				+ "black and cold and has not been touched for ten years.\n\n"
				+ "There is a figure waiting for you at the foot of the "
				+ "tower. Grey robe. A censer on a chain in their hand, "
				+ "the bowl already open, smoke the colour of a bruise "
				+ "rising off it into the wrong-coloured sky.\n\n"
				+ "They know you. You know them.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Walk closer. Let them speak first.",
				function getResult(_event) { return "B"; }
			}],
			function start(_event) {}
		});

		// Screen B — the confrontation. Option launches scripted combat.
		this.m.Screens.push({
			ID   = "B",
			Text = "[img]gfx/ui/events/event_145.png[/img]"
				+ "{They speak before you are within twenty paces.\n\n"
				+ "'You kept it,' they say. Meaning the lantern. They are "
				+ "not surprised. They are not angry. They sound — if you "
				+ "are being honest — almost gentle, the way someone is "
				+ "gentle with a friend who has been holding on to the "
				+ "wrong thing for a long time.\n\n"
				+ "'The order was over,' they say. 'The order was over in "
				+ "the plague year, and we were the ones who stayed to "
				+ "pretend otherwise. I stopped pretending. I did you the "
				+ "kindness of not inviting you to stop with me. But you "
				+ "came anyway.'\n\n"
				+ "They lift the censer. The smoke thickens.\n\n"
				+ "'Put the lantern down. I will put the censer down. We "
				+ "will sit at the foot of the tower and drink whatever "
				+ "this month's apprentice would have brought us, and I "
				+ "will tell you what is on the other side of all of this, "
				+ "and you will see that I am not wrong. I am not wrong, "
				+ "and I did not betray the order — the order betrayed "
				+ "itself, and I refused to die for a thing that was "
				+ "already dead.'\n\n"
				+ "You look at the lantern. The ember is burning. It is "
				+ "not as bright as you want it to be. It is, all the "
				+ "same, burning.\n\n"
				+ "You have an answer.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "\"No. The light keeps. That is what it is for.\"",
				function getResult(_event) {
					_event._launchReckoningCombat();
					return 0;
				}
			}],
			function start(_event) {}
		});

		// Screen D — Victory: pick up the cleansed censer.
		// (This screen is registered via registerToShowAfterCombat with the
		// "Victory" outcome. The Vigil Censer is already in the corpse loot
		// UI by this point — injected by the Extinguisher's onDeath.)
		this.m.Screens.push({
			ID   = "D",
			Text = "[img]gfx/ui/events/event_159.png[/img]"
				+ "{You lift the censer out of their hand. It is still warm "
				+ "from the miasma-smoke but the warmth is dying as you "
				+ "touch it — something in the brass remembers what it was "
				+ "supposed to be, what it was before it was made for this, "
				+ "and the bowl comes clean the way a good cloth comes "
				+ "clean under your thumb. You can see it happen.\n\n"
				+ "The recordkeeper is beside you. They are crying quietly. "
				+ "They set a hand against the iron ember-bowl at the top "
				+ "of the tower — no flame there, but the hand is on it, "
				+ "a priest's gesture on a cold altar. You understand what "
				+ "they are doing and you let them do it.\n\n"
				+ "You carry the censer back to the company. The chain is "
				+ "heavy. The bowl is clean. The ember in your lantern is "
				+ "brighter than it has been in a month.\n\n"
				+ "You will burn it. On the way home, at a waypoint where "
				+ "the oil is cheap and the sky is the right colour, you "
				+ "will light the censer and carry it beside the lantern. "
				+ "Two flames. For the two towers. For the order that is "
				+ "ending in a way it gets to choose.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Ride east. The watch holds.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// v2.1.0 — Vigil Censer no longer stash-spawned here; it
				// drops from the Extinguisher's corpse (injected in his
				// onDeath). This screen is the narrative payoff after
				// the loot screen has already been seen.

				// Arc-close flag — moved here from onFinish so a Defeat
				// outcome doesn't accidentally close the arc.
				try { ::World.Flags.set("CinderwatchReckoningComplete", true); } catch (e) {}
				try { ::World.Flags.set("CinderwatchExtinguisherDefeated", true); } catch (e) {}

				// Narrative payoff — renown + mood bump across the company.
				try { ::World.Assets.addBusinessReputation(100); } catch (e) {}
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(4.0, "The western tower is silent but no longer dark. The order's last enemy is down."); } catch (e) {}
					}
				} catch (e) {}
			}
		});

		// Screen DEFEAT — combat lost / retreated. Arc stays open.
		this.m.Screens.push({
			ID   = "DEFEAT",
			Text = "[img]gfx/ui/events/event_29.png[/img]"
				+ "{You pull the company back from the dead tower. The "
				+ "Extinguisher is still standing at its foot, censer "
				+ "in hand, the smoke not thinned at all by what you "
				+ "tried to do.\n\n"
				+ "They do not chase. They do not laugh. They simply "
				+ "watch you go, the way someone watches a friend who "
				+ "still hasn't understood.\n\n"
				+ "The watch will have to be kept another way. The "
				+ "tower will have to be approached again — when the "
				+ "company is mended, when the lantern is steady, when "
				+ "you are sure of your hand on the chain.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Mourn the dead. Mend what's mendable.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// Mood penalty across the company — they retreated, they lost
				// brothers, the western tower is still corrupted.
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.worsenMood(2.0, "The watch was kept badly today. The dead tower is still dark."); } catch (e) {}
					}
				} catch (e) {}
				// Note: CinderwatchReckoningComplete stays UNSET here so the
				// event re-scores tomorrow.
			}
		});
	}

	function _launchReckoningCombat()
	{
		local playerPos = ::World.State.getPlayer().getPos();
		local properties = ::World.State.getLocalCombatProperties(playerPos);
		properties.CombatID = "CinderwatchReckoning";
		properties.IsAutoAssigningBases = true;
		properties.Entities = [];

		// The Extinguisher — registered Troop spec wraps the boss script.
		if ("CinderwatchExtinguisher_Spec" in ::Const.World.Spawn.Troops) {
			local boss = clone ::Const.World.Spawn.Troops.CinderwatchExtinguisher_Spec;
			boss.Faction <- ::Const.Faction.Enemy;
			properties.Entities.push(boss);
		}

		// Music — undead/holy-war tone fits the wrong-coloured sky imagery.
		try { properties.Music = ::Const.Music.UndeadTracks; } catch (e) {}

		// Register the post-combat resolution screens. "D" runs on victory,
		// "DEFEAT" runs on rout / retreat. registerToShowAfterCombat tells
		// BB to re-open this same event after combat resolves and jump
		// directly to the named screen.
		this.registerToShowAfterCombat("D", "DEFEAT");

		::World.State.startScriptedCombat(properties, false, false, true);
	}

	function isValid()
	{
		if (::World == null) return false;
		local scenarioID = "";
		try { scenarioID = ::World.Assets.getOrigin().getID(); } catch (e) { return false; }
		local scenarioOK = (scenarioID == "scenario.cinderwatch") || (scenarioID == "scenario.three_musketeers")
			|| (scenarioID == "scenario.golden_throne" && ::Cinderwatch._hasCinderwardenInRoster());
		if (!scenarioOK) return false;

		if (::World.getTime().Days < 310) return false;
		if (::World.Flags.get("CinderwatchApproachComplete") != true) return false;
		if (::World.Flags.get("CinderwatchReckoningComplete") == true) return false;

		// Settlement guard — don't fire mid-settlement-screen, the combat
		// launch needs the player on the world map. Belt-and-suspenders.
		try {
			if (::World.State.getCurrentState() == ::World.State.getSettlementState()) return false;
		} catch (e) {}

		return true;
	}

	function onUpdateScore()
	{
		this.m.Score = this.isValid() ? 100 : 0;
	}

	function onFinish()
	{
		// v2.1.0 — flag-set moved to D's start() so a Defeat outcome
		// doesn't accidentally close the arc. onFinish is now empty.
	}
});
