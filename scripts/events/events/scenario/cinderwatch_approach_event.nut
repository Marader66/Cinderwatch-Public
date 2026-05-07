// Western Tower questline — Beat 2: The Approach.
//
// Fires once at Day ≥ 250 if Beat 1 (Western Rumor) has landed and Beat 2
// hasn't yet fired. The company arrives at the western reaches and either
// engages Flesh Mender scouts (real scripted combat as of v2.6.0) or
// bypasses them via a narrative path.
//
// v2.0.0: narrative-only. Both paths set CinderwatchApproachComplete.
// v2.6.0: replaced the narrated combat with real scripted tactical
// combat. 4× Cultist + 1× Hexe (the leader with the censer) — Davkul-
// adjacent corruption cult, vanilla troop specs. Same Faction.Enemy +
// registerToShowAfterCombat pattern the Reckoning uses. Bypass path is
// preserved for players who want to skip the engagement.
this.cinderwatch_approach_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID       = "event.cinderwatch_approach";
		this.m.Title    = "The Western Reach";
		this.m.Cooldown = 9999.0 * ::World.getTime().SecondsPerDay;

		// Screen A — arrival in the west
		this.m.Screens.push({
			ID   = "A",
			Text = "[img]gfx/ui/events/event_29.png[/img]"
				+ "{You know you are in the west before the landmarks confirm "
				+ "it. The sky does something different here — a thin, "
				+ "greyish-yellow quality to the light that reminds you of "
				+ "nothing so much as the watchroom in the hour before "
				+ "dawn. Birds quieter than they should be. Road-dust "
				+ "darker than it should be.\n\n"
				+ "The western twin tower is still a day's ride away, but "
				+ "something is out here that shouldn't be. The recordkeeper "
				+ "sees it first — marks in the earth off the main road, "
				+ "wrong kind of footprints, something dragged. They mark "
				+ "the direction in their book and close it.\n\n"
				+ "The wanderer has an arrow nocked before you have said "
				+ "anything. The quartermaster is counting the company "
				+ "without looking like he's counting.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Follow the tracks. Whatever is out there, we meet it now.",
				function getResult(_event) { return "B"; }
			}, {
				Text = "Press on to the tower. They'll come to us if they want us.",
				function getResult(_event) { return "C"; }
			}],
			function start(_event) {}
		});

		// Screen B — pre-combat. Player sees the Menders, decides to engage.
		// Selecting "Form up. Engage." launches the scripted combat via
		// _launchApproachCombat(); Victory routes to BVICTORY, defeat /
		// retreat to BDEFEAT.
		this.m.Screens.push({
			ID   = "B",
			Text = "[img]gfx/ui/events/event_145.png[/img]"
				+ "{You find them at dusk — five of them, Mender-kind, "
				+ "wearing robes the colour of wet ash. They have set a "
				+ "small camp in a thicket off the road. They were watching "
				+ "it. They were watching for you specifically; you know "
				+ "this because one of them drops a parchment when they "
				+ "see you coming and the parchment has your lantern "
				+ "sketched in the corner of the map.\n\n"
				+ "The Menders move like people who were doctors once — "
				+ "precise, indifferent, humming something under their "
				+ "breath you cannot make out. One of them stands a pace "
				+ "behind the others, an older woman with a small censer "
				+ "on her belt, the smoke off it the wrong colour for "
				+ "evening. You catch yourself looking at the censer "
				+ "longer than you mean to.\n\n"
				+ "They will not surrender. The miasma is already rising. "
				+ "Time to keep the watch.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Form up. Engage.",
				function getResult(_event) {
					_event._launchApproachCombat();
					return 0;
				}
			}, {
				Text = "We have no quarrel here. Withdraw and ride past.",
				function getResult(_event) { return "C"; }
			}],
			function start(_event) {}
		});

		// Screen BVICTORY — post-victory narrative. Routes via
		// registerToShowAfterCombat. Sets CinderwatchApproachCombat
		// (Reckoning reads this) and grants renown + mood.
		this.m.Screens.push({
			ID   = "BVICTORY",
			Text = "[img]gfx/ui/events/event_159.png[/img]"
				+ "{It was an ugly skirmish. The Menders fought like the "
				+ "doctors they were — precise, indifferent, humming "
				+ "something under their breath even at the end. The ember "
				+ "stayed bright throughout. The cleansing warmth kept "
				+ "the miasma they poured out from settling on your "
				+ "people.\n\n"
				+ "By the time it ends you have the censer in your hand "
				+ "and you do not quite know why you picked it up. You "
				+ "put it down at the edge of the camp and leave it. It "
				+ "is not yours to carry. Not yet.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "They knew we were coming. Push to the tower.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				// Renown + mood payoff for actually winning the engagement.
				try { ::World.Assets.addBusinessReputation(50); } catch (e) {}
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.improveMood(2.0, "Scouts of the Flesh Menders down. The tower is close."); } catch (e) {}
					}
				} catch (e) {}
				// Flag: approach completed via combat path. Reckoning reads
				// this to know how much the Extinguisher's retinue was
				// softened by the Beat 2 fight.
				try { ::World.Flags.set("CinderwatchApproachCombat", true); } catch (e) {}
			}
		});

		// Screen BDEFEAT — retreat / loss. The arc still continues
		// (CinderwatchApproachComplete fires in onFinish regardless), but
		// no renown bonus and a mood penalty.
		this.m.Screens.push({
			ID   = "BDEFEAT",
			Text = "[img]gfx/ui/events/event_29.png[/img]"
				+ "{You pull the company back through the trees. The "
				+ "miasma follows for fifty paces, thins, gives up. The "
				+ "Menders do not pursue. They have what they wanted, "
				+ "which is to know how the company moves under fire.\n\n"
				+ "The recordkeeper marks the engagement in their book "
				+ "and closes it without comment. The wanderer is checking "
				+ "on the wounded. The quartermaster is counting the "
				+ "company without looking like he's counting.\n\n"
				+ "The watch will have to be kept another way. The tower "
				+ "is still ahead.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "Mend what's mendable. Keep moving west.",
				function getResult(_event) { return 0; }
			}],
			function start(_event)
			{
				try {
					foreach (bro in ::World.getPlayerRoster().getAll()) {
						try { bro.worsenMood(1.5, "The Menders had our measure. The watch was kept badly today."); } catch (e) {}
					}
				} catch (e) {}
			}
		});

		// Screen C — bypass the scouts (narrated)
		this.m.Screens.push({
			ID   = "C",
			Text = "{You ride past the tracks. The company is tight — alert "
				+ "in the way veterans get alert when they're trying not to "
				+ "look alert. The tracks stay parallel to the road for an "
				+ "afternoon and then peel off northward, toward the tower.\n\n"
				+ "Whoever they were, they got there first. When you reach "
				+ "the tower they will be inside it, waiting. You know this. "
				+ "The quartermaster knows this. The recordkeeper marks the "
				+ "detour in their book with a small, careful line.\n\n"
				+ "You gained a day. You gave up the chance to thin them. "
				+ "That was a trade. Trades are trades.}",
			Image      = "",
			Banner     = "",
			List       = [],
			Characters = [],
			Options = [{
				Text = "To the tower.",
				function getResult(_event) { return 0; }
			}],
			function start(_event) {}
		});
	}

	// v2.6.0 — scripted Beat 2 combat. Five Flesh Mender scouts: 4 vanilla
	// cultists (rank-and-file Davkul-flavored corruption cult, robes the
	// colour of wet ash) + 1 hexe (the older woman with the censer, the
	// scouting party's lead). Vanilla troop specs only — no DLC gating.
	// Faction set to Enemy. registerToShowAfterCombat routes to BVICTORY
	// on win, BDEFEAT on loss/retreat. Mirrors Beat 3 Reckoning's
	// _launchReckoningCombat pattern.
	function _launchApproachCombat()
	{
		local playerPos = ::World.State.getPlayer().getPos();
		local properties = ::World.State.getLocalCombatProperties(playerPos);
		properties.CombatID = "CinderwatchApproach";
		properties.IsAutoAssigningBases = true;
		properties.Entities = [];

		// 4× rank-and-file Mender cultists.
		if ("Cultist" in ::Const.World.Spawn.Troops) {
			for (local i = 0; i < 4; i++) {
				local scout = clone ::Const.World.Spawn.Troops.Cultist;
				scout.Faction <- ::Const.Faction.Enemy;
				properties.Entities.push(scout);
			}
		}

		// 1× Hexe — the older woman with the censer. Vanilla; base game.
		if ("Hexe" in ::Const.World.Spawn.Troops) {
			local leader = clone ::Const.World.Spawn.Troops.Hexe;
			leader.Faction <- ::Const.Faction.Enemy;
			properties.Entities.push(leader);
		}

		// If neither Cultist nor Hexe specs registered (extreme edge case —
		// vanilla mod stack absent?), fall back to bandit veterans so the
		// combat still launches and the questline doesn't soft-lock.
		if (properties.Entities.len() == 0
			&& "BanditVeteran" in ::Const.World.Spawn.Troops)
		{
			for (local i = 0; i < 5; i++) {
				local fallback = clone ::Const.World.Spawn.Troops.BanditVeteran;
				fallback.Faction <- ::Const.Faction.Enemy;
				properties.Entities.push(fallback);
			}
		}

		// Tone — the Menders are corruption, not the dead. Avoid the
		// undead music tracks; let BB pick the default ambush music.
		// (No properties.Music override.)

		this.registerToShowAfterCombat("BVICTORY", "BDEFEAT");
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
		if (::World.getTime().Days < 250) return false;
		if (::World.Flags.get("CinderwatchWesternRumorHeard") != true) return false;
		if (::World.Flags.get("CinderwatchApproachComplete") == true) return false;

		// Settlement guard — combat-launching options need the player on
		// the world map. Mirrors the Reckoning event's belt-and-suspenders.
		try {
			if (::World.State.getCurrentState() == ::World.State.getSettlementState()) return false;
		} catch (e) {}

		return true;
	}

	function onUpdateScore()
	{
		this.m.Score = 0;
		if (!this.isValid()) return;
		this.m.Score = 90;
	}

	function onFinish()
	{
		try { ::World.Flags.set("CinderwatchApproachComplete", true); } catch (e) {}
	}
});
