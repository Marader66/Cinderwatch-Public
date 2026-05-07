// The Cinderwatch scenario.
//
// Inherits from `tainted_world_scenario` for ROTU world settings — our scenario
// needs to be registered with ROTU to appear in the select UI, and the cleanest
// path is to share its world configuration.
//
// Story
// -----
// The Cinderwatch is one of a pair of watchtowers built on the imperial edge
// to keep vigil over a quiet wound in the world. For centuries the towers kept
// their embers lit — a physical promise that the thing in the dark cannot cross
// the light. Plague ended the order. The Cinderwarden is the last. Now word has
// come from the west: the twin tower's ember has gone out. Someone let it die.
// The Cinderwarden takes to the road to find out who, and to rekindle what was
// let fall.
//
// Mechanical identity
// -------------------
// - The Cinderwarden is a DELIBERATELY mortal origin character. No resurrection,
//   no divine aura, no overwhelming stat pool. They're an old duty-bound soldier
//   with a lamp and a long memory.
// - Watch Points progression: see golden_emperor_trait's Purge Meter for pattern
//   parallel, but inverted. The Cinderwarden gains points by spending turns
//   isolated (≥4 tiles from any ally) — flipping BB's "huddle for aura buffs"
//   meta into an edge-of-formation identity.
// - Brothers gain the `wardens_promise_trait` on hire — lightweight oath, no
//   per-tier complexity like the Emperor's Mandate. Identity over systems.
this.cinderwatch_scenario <- this.inherit("scripts/scenarios/world/tainted_world_scenario", {

	m = {
		ChaosPlagueChance = 10,   // Low — the scenario's own narrative is plague-adjacent
		RavenMarkChance   = 5,
		IntroEvent        = "event.cinderwatch_intro"
	},

	function create()
	{
		this.m.ID   = "scenario.cinderwatch";
		this.m.Name = "The Cinderwatch";
		this.m.Description =
			"[p=c][img]gfx/ui/events/event_06.png[/img][/p]"
			+ "[p]The lesser watchtower on the eastern edge. The plague took "
			+ "the order years ago. The ember burned on, tended by one pair "
			+ "of hands. Now the western twin has gone dark — and the "
			+ "Cinderwarden is riding to learn why.\n\n"
			+ "[color=#FFD700]The Cinderwarden:[/color] A mortal soldier — not "
			+ "a saint or a king. Moderate stats, high Bravery, steady hands. "
			+ "Identity comes from discipline, not divinity.\n"
			+ "[color=#FFD700]Ember of the Watch:[/color] A small personal "
			+ "aura that steadies adjacent allies. Once per battle the "
			+ "Cinderwarden can Rekindle to share their ember's warmth — "
			+ "restoring stamina to everyone nearby.\n"
			+ "[color=#FFD700]The Long Watch:[/color] The Cinderwarden earns "
			+ "Watch Points at turn start when standing four or more tiles "
			+ "from any ally. Milestones unlock stat bumps, an active "
			+ "skill, a permanent aura extension, and a capstone that "
			+ "passes the ember on if they fall.\n"
			+ "[color=#FFD700]Vigilwalker:[/color] Cannot be surprised, "
			+ "immune to stun on the first round of combat. The order "
			+ "taught patience before it taught the spear.\n"
			+ "[color=#FFD700]Warden's Promise:[/color] Every brother who "
			+ "joins the company swears the warden's oath. +5 Resolve, "
			+ "cannot rout while the Cinderwarden lives and fights.[/p]";
		this.m.Difficulty = 2; // Moderate — the scenario's identity is duty, not overwhelming threat
		this.m.Order      = 13;
		this.m.IsFixedLook = true;
		this.m.StartingRosterTier         = this.Const.Roster.getTierForSize(4);
		this.m.StartingBusinessReputation = 80;
		this.m.RosterTierMax              = this.Const.Roster.getTierForSize(25);
		this.m.RosterTierMaxCombat        = this.Const.Roster.getTierForSize(25);
		this.setRosterReputationTiers(this.Const.Roster.createReputationTiers(this.m.StartingBusinessReputation));
	}

	function onSpawnAssets()
	{
		local roster = this.World.getPlayerRoster();

		// ── The Cinderwarden ───────────────────────────────────────────────
		local warden = roster.create("scripts/entity/tactical/player");
		warden.m.HireTime = this.Time.getVirtualTimeF();
		warden.setStartValuesEx(["cinderwarden_background"]);
		warden.getBackground().buildDescription(true);

		// Gender-aware titling — "Warden" is already gender-neutral, so we
		// don't split the display name the way Golden Throne does for
		// Emperor/Empress. Keep one title; let the player fill in their own
		// name if they want.
		warden.setName("The Cinderwarden");
		warden.setTitle("of the Eastern Watch");

		// Scrub ROTU's default Davkul trait — the Cinderwatch origin has its
		// own progression trait, and leaving Davkul in conflicts.
		warden.getSkills().removeByID("trait.rotu_davkul_champion");

		// Core identity traits:
		//   cinderwarden_trait — Watch Points + tier unlocks (the driver)
		//   vigilwalker_trait  — passive immunities (anti-surprise, first-round
		//                        stun immunity, quiet morale)
		warden.getSkills().add(::new("scripts/skills/traits/cinderwarden_trait"));
		warden.getSkills().add(::new("scripts/skills/traits/vigilwalker_trait"));

		// A couple of thematic vanilla traits — these aren't the Cinderwarden's
		// signature identity but they match the character fantasy: tough old
		// soldier, slow to break, one good surviving eye.
		warden.getSkills().add(::new("scripts/skills/traits/tough_trait"));
		warden.getSkills().add(::new("scripts/skills/traits/determined_trait"));

		warden.setPlaceInFormation(4);
		warden.getFlags().set("IsPlayerCharacter", true);
		warden.getFlags().set("Cinderwarden", true);

		// Sprite brush: v1.3.2 — was `bust_base_hedge_knight` which threw
		// a single "Unknown Brush requested" warning on spawn. That brush
		// isn't registered in vanilla or Legends despite reading like a
		// plausible vanilla identifier. Swapped to `bust_base_crusader`
		// (verified in vanilla + Legends — used by legends_crusader_scenario
		// and Golden Throne's Emperor). Thematically still reads right:
		// the Cinderwatch order shares visual DNA with the crusader orders
		// (chain + tabard, ember-bearers descended from holy defenders).
		warden.getSprite("socket").setBrush("bust_base_crusader");

		warden.m.Level = 1;
		warden.setVeteranPerks(2);

		// Moderate warrior stats — emphatically NOT godly. The character's
		// strength is positional discipline and the ember, not raw numbers.
		local b = warden.getBaseProperties();
		b.Hitpoints     = 75;
		b.Stamina       = 95;
		b.MeleeSkill    = 75;
		b.RangedSkill   = 50;  // Vigilant — they watch, and they see.
		b.MeleeDefense  = 25;
		b.RangedDefense = 15;
		b.Bravery       = 100; // Duty is their wall.
		b.Initiative    = 55;

		warden.m.Talents = [];
		warden.m.Attributes = [];
		local talents = warden.getTalents();
		talents.resize(this.Const.Attributes.COUNT, 0);
		// 3-star Bravery (core identity), Fatigue (long watches), MD
		// (positional specialist). Supporting stars in HP + MS.
		talents[this.Const.Attributes.Bravery]      = 3;
		talents[this.Const.Attributes.Fatigue]      = 3;
		talents[this.Const.Attributes.MeleeDefense] = 3;
		talents[this.Const.Attributes.Hitpoints]    = 2;
		talents[this.Const.Attributes.MeleeSkill]   = 2;
		warden.fillAttributeLevelUpValues(this.Const.XP.MaxLevelWithPerkpoints - 1);

		// ── Starting equipment — the watcher's kit ─────────────────────────
		// Layered Legends armor: gambeson base + chain hauberk upgrade.
		// Deliberately not plate — this character isn't a bulwark, they're a
		// spear-and-lantern silhouette. No cloak either; the order was
		// austere.
		local items = warden.getItems();
		items.unequip(items.getItemAtSlot(this.Const.ItemSlot.Body));
		items.unequip(items.getItemAtSlot(this.Const.ItemSlot.Head));
		items.unequip(items.getItemAtSlot(this.Const.ItemSlot.Mainhand));
		items.unequip(items.getItemAtSlot(this.Const.ItemSlot.Offhand));

		local body = this.new("scripts/items/legend_armor/cloth/legend_armor_gambeson");
		body.setUpgrade(this.new("scripts/items/legend_armor/chain/legend_armor_hauberk_full"));
		items.equip(body);

		// Helmet: chain coif under an open kettle hat. The Cinderwarden looks
		// at the world with their own eyes — no great-helm visor imagery. The
		// lantern is their vision aid, not a helmet slot.
		local head = this.new("scripts/items/legend_helmets/hood/legend_helmet_chain_hood");
		head.setUpgrade(this.new("scripts/items/legend_helmets/helm/legend_helmet_kettle_hat"));
		items.equip(head);

		// Mainhand: a billhook. Polearms suit the watchtower identity (reach,
		// kept at arm's length from the thing in the dark), and the billhook
		// specifically is a tool-of-a-watcher weapon — pruning, dragging,
		// keeping things off walls.
		items.equip(this.new("scripts/items/weapons/billhook"));

		// Starting trinket: the brass lantern. Goes in the offhand / tool
		// slot; it's passive (stat bonuses + vision) rather than an active
		// skill container.
		local lantern = this.new("scripts/items/misc/brass_lantern_trinket");
		items.equip(lantern);

		// Starting perks — a patient defender's set. Legends-hooked vanilla
		// perks inherit Legends' enhanced behavior when Legends is loaded.
		// v1.2.1: Spearwall and PolearmMastery are NOT in PerkDefs — they're
		// weapon-skill mastery perks that live in the perk-tree registry but
		// aren't registered as PerkDef entries. Tried to reference them →
		// "index does not exist" throw at onSpawnAssets, aborting character
		// setup and freezing the game. Swapped for verified-valid PerkDefs
		// that fit the watchman fantasy:
		//   Spearwall     → FortifiedMind (fear/stun resistance — patience)
		//   PolearmMastery→ Brawny (armor fatigue reduction — layered chain)
		// Both confirmed in mod_legends-19.3.17/!!config/perks_defs.nut.
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.BattleForged,    0);
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.Colossus,        1);
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.SteelBrow,       2);
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.Gifted,          3);
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.Rotation,        4);
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.FortifiedMind,   5);
		addScenarioPerk(warden.getBackground(), ::Const.Perks.PerkDefs.Brawny,          6);

		// v2.5.0 — FoTN endgame perks (Light path matches the Cinderwarden's
		// "stand alone for power" Watch Points design). Skipped if FoTN
		// isn't loaded.
		try { ::Cinderwatch._applyFoTNCinderwarden(warden); }
		catch (e) { ::logWarning("[mod_cinderwatch] _applyFoTNCinderwarden: " + e); }

		// v2.5.0 — PoV mutagen at 100% (vs golden_knight_ally's 40% rolled).
		// The Cinderwarden's identity is positional discipline; the mutagen
		// adds an extra layer of weirdness on top of the watch fantasy.
		// Skipped if PoV isn't loaded.
		try { ::Cinderwatch._applyPoVMutagenCinderwarden(warden, 100); }
		catch (e) { ::logWarning("[mod_cinderwatch] _applyPoVMutagenCinderwarden: " + e); }

		// ── Starting Party ─────────────────────────────────────────────────
		// Small — only 3 brothers. This isn't an army. It's a handful of
		// people who refused to leave when the order died, plus the warden.
		// The roster grows through hiring like any other campaign.
		local grantWardenTraits = function (bro) {
			bro.getSkills().add(::new("scripts/skills/traits/wardens_promise_trait"));
		};

		// 1 Retired Soldier — the order's quartermaster, too old to leave,
		// too stubborn to die of plague.
		local quartermaster = roster.create("scripts/entity/tactical/player");
		quartermaster.setStartValuesEx(["retired_soldier_background"]);
		quartermaster.getBackground().buildDescription(true);
		grantWardenTraits(quartermaster);
		quartermaster.m.HireTime = this.Time.getVirtualTimeF();
		quartermaster.setPlaceInFormation(3);

		// 1 Monk — the order's recordkeeper, a lay-brother who kept the
		// watch-logs for twenty years.
		local recordkeeper = roster.create("scripts/entity/tactical/player");
		recordkeeper.setStartValuesEx(["monk_background"]);
		recordkeeper.getBackground().buildDescription(true);
		grantWardenTraits(recordkeeper);
		recordkeeper.m.HireTime = this.Time.getVirtualTimeF();
		recordkeeper.setPlaceInFormation(5);

		// 1 Hedge Knight — a wandering sword who showed up to the plague
		// tower because nobody else would, and found themselves staying.
		local wanderer = roster.create("scripts/entity/tactical/player");
		wanderer.setStartValuesEx(["hedge_knight_background"]);
		wanderer.getBackground().buildDescription(true);
		grantWardenTraits(wanderer);
		wanderer.m.HireTime = this.Time.getVirtualTimeF();
		wanderer.setPlaceInFormation(6);

		// ── Resources ──────────────────────────────────────────────────────
		// v2.3.0: cut to 1/4 of prior values (250/100/80/100 → 60/25/20/25).
		// The order rode west on what they could carry. Most of the tower's
		// wealth was spent on oil and vigil-supplies over the decades —
		// what reaches the company is a token of the order, not a treasury.
		this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
		::World.Assets.getStash().resize(::World.Assets.getStash().getCapacity() + 10);
		this.World.Assets.m.Money      += 60;
		this.World.Assets.m.ArmorParts += 25;
		this.World.Assets.m.Medicine   += 20;
		this.World.Assets.m.Ammo       += 25;
	}

	function onSpawnPlayer()
	{
		// v2.4.6: try Raven's Nest first (player-allied ROTU Steward holding)
		// so spawn is always next to a friendly settlement. Falls through
		// to vanilla village pick if Steward isn't loaded.
		local tile = null;
		if ("Rotu_Steward" in ::getroottable()
			&& "spawnInitialPlayerSettlements" in ::Rotu_Steward)
		{
			local holdings = ::Rotu_Steward.spawnInitialPlayerSettlements();
			if (holdings != null && holdings.len() > 0) {
				local pick = holdings[::Math.rand(0, holdings.len() - 1)];
				tile = ::Rotu_Steward.findAdjacentSpawnTile(pick, 4);
			}
		}

		if (tile == null) {
			// Vanilla fallback: small village on a road (matches GT pattern).
			local randomVillage;
			for (local i = 0; i != this.World.EntityManager.getSettlements().len(); ++i) {
				randomVillage = this.World.EntityManager.getSettlements()[i];
				if (!randomVillage.isMilitary()
					&& !randomVillage.isIsolatedFromRoads()
					&& randomVillage.getSize() == 1)
				{
					break;
				}
			}
			tile = randomVillage.getTile();
			do {
				local x = this.Math.rand(
					this.Math.max(2, tile.SquareCoords.X - 1),
					this.Math.min(this.Const.World.Settings.SizeX - 2, tile.SquareCoords.X + 1));
				local y = this.Math.rand(
					this.Math.max(2, tile.SquareCoords.Y - 1),
					this.Math.min(this.Const.World.Settings.SizeY - 2, tile.SquareCoords.Y + 1));
				if (!this.World.isValidTileSquare(x, y)) continue;
				local t = this.World.getTileSquare(x, y);
				if (t.Type == this.Const.World.TerrainType.Ocean
					|| t.Type == this.Const.World.TerrainType.Shore) continue;
				if (t.getDistanceTo(tile) == 0) continue;
				if (!t.HasRoad) continue;
				tile = t;
				break;
			} while (1);
		}

		this.World.State.m.Player = this.World.spawnEntity(
			"scripts/entity/world/player_party",
			tile.Coords.X, tile.Coords.Y
		);

		// Party look: v1.3.2 — was `figure_player_militia` which isn't a
		// registered figure-player brush (Legends comments out every
		// non-crusader figure_player ref, suggesting they're all phantoms
		// outside the crusader one). Rather than copy crusader and make
		// the Cinderwatch look identical to Golden Throne on the world
		// map, just skip the custom party look — BB's default mercenary-
		// company figure fits the modest-order-of-watchers fantasy better
		// than a shared crusader silhouette would.
		// ::World.Flags.set("ModCustomPartyLook", ...);
		// ::World.Assets.updateLook();
		::World.Ambitions.getAmbition("ambition.make_nobles_aware").setDone(true);
		this.World.getCamera().setPos(this.World.State.m.Player.getPos());

		// Intro event fires one second after spawn.
		// v2.0.1: gate on `CinderwatchIntroSeen` world flag to block any
		// re-fire scenarios (save-load edge cases, campaign-restart oddities,
		// event-pool retries). The intro's own onFinish sets the flag, so a
		// completed intro can never fire again.
		local introEvent = this.m.IntroEvent;
		this.Time.scheduleEvent(this.TimeUnit.Real, 1000, function(_tag) {
			// v2.4.7: scenario music. Was forged_in_fire which is MWU-only-
			// referenced (no actual file on disk) and FATAL'd BB on launch
			// — see WORKLOG entry "post-EOD-5-rollback". noble_02 is a
			// Legends-referenced vanilla track, order/vigil-flavored.
			try {
				this.Music.setTrackList(["music/noble_02.ogg"], this.Const.Music.CrossFadeTime);
			} catch (e) {}
			if (introEvent == null) return;
			if (::World != null && ::World.Flags.get("CinderwatchIntroSeen") == true) return;
			this.World.Events.fire(introEvent);
		}, null);
	}

	function onInit()
	{
		this.starting_scenario.onInit();
		this.World.Assets.m.BrothersMaxInCombat = 25;
		this.World.Assets.m.BrothersScaleMax    = 20;
		// v2.3.0: bumped from +3 to +20. With the resource cut, the order
		// arrives lean but well-provisioned for the road — they brought
		// what they could on the cart instead of in the purse.
		this.World.Assets.m.FoodAdditionalDays += 20;
		this.World.Assets.m.ExtraLootChance     = 4;

		// v1.1.0 — register the atmospheric flavor events. Each event's
		// own onUpdateScore gates firing (day threshold + once-flag),
		// so BB's event scoring will pick whichever is eligible each tick.
		// These events are scoped to this scenario only (they check the
		// origin ID in onUpdateScore), so no need to wrap in scenario-type
		// checks here.
		this.World.Events.addSpecialEvent("event.cinderwatch_road_shrine");
		this.World.Events.addSpecialEvent("event.cinderwatch_messenger");

		// v2.0.0 — Western Tower questline. Three narrative beats
		// (Rumor Day 150 → Approach Day 250 → Reckoning Day 310) + two
		// atmospheric events interleaved. Gates chain through world
		// flags: Rumor requires `CinderwatchMessengerReturned` (set by
		// Day-70 messenger); Approach requires `CinderwatchWesternRumorHeard`;
		// Reckoning requires `CinderwatchApproachComplete`. Dim Ember and
		// Dark Grows are window-gated between beats with narrative
		// prerequisites. See CLAUDE.md "Western Tower questline" section
		// for the full trigger matrix.
		this.World.Events.addSpecialEvent("event.cinderwatch_western_rumor");
		this.World.Events.addSpecialEvent("event.cinderwatch_dim_ember");
		this.World.Events.addSpecialEvent("event.cinderwatch_approach");
		this.World.Events.addSpecialEvent("event.cinderwatch_dark_grows");
		this.World.Events.addSpecialEvent("event.cinderwatch_reckoning");
		// v2.5.0 — Inheritor succession event. Fires when the warden has
		// died at Watch Tier IV and the inheritor was promoted (flag set
		// in cinderwarden_trait.onDeath). One-shot per campaign.
		this.World.Events.addSpecialEvent("event.cinderwatch_succession");
	}

	// Campaign ends if the Cinderwarden is gone (with no resurrection clause
	// — unlike the Emperor, there is no second chance). Over-check with the
	// Cinderwarden flag rather than IsPlayerCharacter so that a brother
	// promoted via Undying-Vigil-style mechanic in a future version can
	// cleanly take over the PlayerCharacter flag without ending the scenario.
	function onCombatFinished()
	{
		foreach (bro in this.World.getPlayerRoster().getAll()) {
			if (bro.getFlags().get("Cinderwarden")
				|| bro.getFlags().get("IsPlayerCharacter"))
			{
				return true;
			}
		}
		return false;
	}

	// Every hire swears the Warden's Promise. It's a small oath — no per-tier
	// machinery, just a flat identity trait. The point is that the company
	// SHARES A VOW, not that it has a system of vow-progression on top of it.
	function onHiredByScenario(bro)
	{
		// v2.0.2: try/catch each step so one failure (transient
		// null-field on a freshly-hired bro, skill-add conflict, mood
		// API variance) can't leave the brother half-initialized. Each
		// operation is independent and missing one isn't fatal.
		if (bro == null) return;
		try { if (bro.getFlags().get("IsPlayerCharacter")) return; } catch (e) {}
		try { bro.getSkills().add(::new("scripts/skills/traits/wardens_promise_trait")); } catch (e) {
			::logWarning("[mod_cinderwatch] onHiredByScenario: Promise add failed: " + e);
		}
		try { bro.improveMood(2.0, "The Cinderwarden has taken my oath. I keep the watch."); } catch (e) {}
	}

	// Hiring roster — weighted toward disciplined martial archetypes. The
	// Cinderwarden's company draws people who've made peace with duty; the
	// weights reflect that. Loosened a bit to avoid making the campaign feel
	// claustrophobic.
	function onUpdateHiringRoster(_roster)
	{
		this.addBroToRoster(_roster, "retired_soldier_background",          18);
		this.addBroToRoster(_roster, "hedge_knight_background",             18);
		this.addBroToRoster(_roster, "sellsword_background",                15);
		this.addBroToRoster(_roster, "legend_man_at_arms_background",       15);
		this.addBroToRoster(_roster, "squire_background",                   12);
		this.addBroToRoster(_roster, "legend_shieldmaiden_background",      12);
		this.addBroToRoster(_roster, "monk_background",                     10);
		this.addBroToRoster(_roster, "hunter_background",                   10);
		this.addBroToRoster(_roster, "bowyer_background",                   8);
		this.addBroToRoster(_roster, "bastard_background",                  8);
		this.addBroToRoster(_roster, "witchhunter_background",              8);
		this.addBroToRoster(_roster, "beast_hunter_background",             8);
		this.addBroToRoster(_roster, "paladin_background",                  7);
		this.addBroToRoster(_roster, "adventurous_noble_background",        6);
		this.addBroToRoster(_roster, "flagellant_background",               6);
		this.addBroToRoster(_roster, "barbarian_background",                5);
		this.addBroToRoster(_roster, "killer_on_the_run_background",        4);
		this.addBroToRoster(_roster, "assassin_background",                 4);
		// ROTU special backgrounds — commanders show up more rarely than in
		// Golden Throne because this scenario is about the warden's own
		// watchfulness, not about gathering legends.
		this.addBroToRoster(_roster, "legend_assassin_commander_background", 12);
		this.addBroToRoster(_roster, "legend_ranger_commander_background",   12);
		this.addBroToRoster(_roster, "raven_bow_background",                 15);
		this.addBroToRoster(_roster, "dark_guard_background",                10);
		this.addBroToRoster(_roster, "oldling_background",                   15);

		if (::HasPoV) {
			this.addBroToRoster(_roster, "pov_vattghern_background", 15);
			this.addBroToRoster(_roster, "pov_seer_background",      15);
		}
	}
});
