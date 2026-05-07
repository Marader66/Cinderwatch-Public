// The Cinderwarden — origin background for the Cinderwatch scenario.
//
// DESIGN NOTES:
// - Deliberately mortal. No resurrection, no morale-immune-always, no stat
//   multipliers. The signature mechanic lives in the cinderwarden_trait
//   (Watch Points + tier unlocks), not in the background itself.
// - One small stat bump on the background: +5 Initiative, because the order
//   taught vigilance, and +3 Resolve, because duty is the wall.
// - Perk trees chosen for the watcher fantasy: polearms + spears (wall-of-
//   reach identity), shields (they stand the wall), long defensive classes,
//   faith/utility magic trees (the lantern's flame is quasi-mystical).
//
// The "once per battle Rekindle" and "Lantern Strike at Watch Tier II" are
// granted via the cinderwarden_trait, not here — keeps the background as
// pure identity / stat shaping and the trait as the mechanical driver.
this.cinderwarden_background <- ::inherit("scripts/skills/backgrounds/character_background", {
	m = {},

	function create()
	{
		character_background.create();
		m.ID                    = "background.cinderwarden";
		m.Name                  = "The Cinderwatch";
		m.Icon                  = "ui/backgrounds/crusader.png";  // vanilla-safe fallback; swap when custom art lands
		m.BackgroundDescription = "Last of the order that tended a watchtower on the imperial edge. They have kept the ember lit alone for more years than they care to count. Now the twin tower in the west has gone dark — and the watcher will not sit quietly while it does.";
		m.GoodEnding            = "The western tower burns again. Not as it did in the order's days — fewer hands, longer silences — but it burns, and the thing in the dark keeps to the dark. That was always all the Cinderwarden asked.";
		m.BadEnding             = "The ember guttered out at the fording. Nothing dramatic; a cold rain, a long ride, an ambush on tired horses. The watch failed. No one was left to notice.";
		m.HiringCost            = 9999999999;
		m.DailyCost             = 0;

		// Excluded traits — the Cinderwarden doesn't roll fear/cowardice
		// traits (they're defined by patience, not cowardice) or morbid
		// impulse traits (they're defined by duty, not despair). The full
		// scrub list is narrower than the Emperor's because the Cinderwarden
		// is a real human who could plausibly have some rough edges — so we
		// permit traits like Impatient, Paranoid, Superstitious that
		// thematically fit a long-vigil character.
		m.Excluded = [
			"trait.fear_undead",
			"trait.fear_beasts",
			"trait.fear_greenskins",
			"trait.legend_fear_nobles",
			"trait.legend_fear_dark",
			"trait.ailing",
			"trait.weasel",
			"trait.tiny",
			"trait.fragile",
			"trait.clumsy",
			"trait.fainthearted",
			"trait.craven",
			"trait.greedy",
			"trait.gluttonous",
			"trait.bleeder",
			"trait.dumb",
			"trait.cocky",
			"trait.disloyal",
			"trait.dastard",
			"trait.drunkard",
			"trait.asthmatic",
			"trait.deathwish",
			"trait.mad",
			"trait.bloodthirsty",
			"trait.legend_slack",
			"trait.legend_unpredictable",
			"trait.legend_double_tongued",
			"trait.legend_cannibalistic",
			"trait.addict"
			// Night_owl / night_blind are NOT excluded — a warden who's
			// adapted to long nights could plausibly roll either.
			// Old is NOT excluded — the Cinderwarden's fantasy accommodates
			// an aging character.
		];

		// No Ranged-skill/defense exclusion. The Cinderwarden isn't a pure
		// melee origin like the Emperor — they're trained to use a
		// crossbow for long-range vigilance, so ranged stats scale
		// normally.
		m.ExcludedTalents = [];

		m.Bodies            = ::Const.Bodies.AllMale;  // override to AllHuman below if we want female option
		this.m.Faces        = this.Const.Faces.AllHuman;
		this.m.Hairs        = null;
		this.m.HairColors   = this.Const.HairColors.All;
		m.BeardChance       = 70;    // Older / more weathered than typical
		m.Modifiers.Ammo    = ::Const.LegendMod.ResourceModifiers.Ammo[0];
		m.AlignmentMax      = ::Const.LegendMod.Alignment.Chivalrous;
		m.AlignmentMin      = ::Const.LegendMod.Alignment.NeutralMax;  // stoic, unromantic

		// Override Bodies to allow female Cinderwarden too — the watchtower
		// order isn't gender-restricted in the fiction.
		m.Bodies = ::Const.Bodies.AllMale;
		// Actually, keep AllMale as the base and let BB roll — changing to
		// AllHuman here breaks Bodies-to-Face mapping in some Legends setups.
		// Leaving as AllMale for v1.0; can revisit in a patch.

		// Perk trees — patient defensive class fantasy.
		m.PerkTreeDynamic = {
			Weapon = [
				this.Const.Perks.SpearTree,
				this.Const.Perks.PolearmTree,
				this.Const.Perks.AxeTree,       // billhooks, spades, watchtower tools
				this.Const.Perks.CrossbowTree   // a watcher's long weapon
			],
			Defense = [
				this.Const.Perks.HeavyArmorTree,
				this.Const.Perks.MediumArmorTree,
				this.Const.Perks.ShieldTree
			],
			Traits = [
				this.Const.Perks.IndestructibleTree,  // Colossus — stands the wall
				this.Const.Perks.FitTree,
				this.Const.Perks.CalmTree,
				this.Const.Perks.IntelligentTree,     // Gifted + Student for a literate order member
				this.Const.Perks.LargeTree
			],
			Enemy = [
				this.Const.Perks.UndeadTree,
				this.Const.Perks.OccultTree,
				// v1.2.1: was `BeastsTree` (phantom — threw "index does not
				// exist" during background create on new campaign). Real const
				// is `BeastTree` (singular). Per Legends' config/
				// z_perks_tree_enemy.nut:7.
				this.Const.Perks.BeastTree            // the Cinderwatch's real enemies
			],
			Class = [
				// v1.2.1: was `PikemanClassTree` which doesn't exist in
				// Legends' class-tree registry. `MilitiaClassTree` is the
				// closest thematic fit — same "watchman with a pole" identity
				// and it's verified in z_perks_tree_class.nut:150.
				this.Const.Perks.MilitiaClassTree,
				this.Const.Perks.LongswordClassTree   // breadth — a veteran with decades of cross-training
			],
			Magic = [
				this.Const.Perks.FaithClassTree       // the ember's faith-adjacent quality
			]
		};
	}

	function getName()
	{
		// Modest orange — embers, not gold. Distinguishes them from the
		// Emperor's full gold visually in tooltips and rosters.
		return this.Const.UI.getColorized(this.character_background.getName(), "#E07A3A");
	}

	function getTooltip()
	{
		local ret = this.character_background.getTooltip();
		ret.push({
			id = 10, type = "text", icon = "ui/icons/special.png",
			text = "The [color=#E07A3A]Ember of the Watch[/color] — a small personal aura that steadies adjacent allies by [color=" + ::Const.UI.Color.PositiveValue + "]+5 Resolve[/color]."
		});
		ret.push({
			id = 11, type = "text", icon = "ui/icons/melee_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5 Initiative[/color], [color=" + ::Const.UI.Color.PositiveValue + "]+3 Resolve[/color]. Patience and training."
		});
		ret.push({
			id = 12, type = "text", icon = "ui/icons/vision.png",
			text = "Cannot be [color=" + ::Const.UI.Color.PositiveValue + "]surprised[/color]. Immune to [color=" + ::Const.UI.Color.PositiveValue + "]Stun[/color] on the first round of combat. The order taught patience before it taught the spear."
		});
		ret.push({
			id = 13, type = "text", icon = "ui/icons/kills.png",
			text = "[color=#E07A3A]The Long Watch[/color] — gains Watch Points while standing four or more tiles from any ally at turn start. Tier unlocks at 10 / 30 / 75 / 150 grant escalating powers."
		});
		ret.push({
			id = 14, type = "text", icon = "ui/icons/days_wounded.png",
			text = "Once per battle, the Cinderwarden can [color=" + ::Const.UI.Color.PositiveValue + "]Rekindle[/color] — restoring stamina to themselves and every ally within three tiles. The ember shared."
		});
		return ret;
	}

	function onBuildDescription()
	{
		return this.m.BackgroundDescription;
	}

	function onAdded()
	{
		if (m.IsNew) {
			getContainer().add(::new("scripts/skills/traits/player_character_trait"));
			getContainer().add(::new("scripts/skills/traits/iron_lungs_trait"));
			getContainer().add(::new("scripts/skills/traits/cinderwarden_trait"));
			getContainer().add(::new("scripts/skills/traits/vigilwalker_trait"));
			getContainer().add(::new("scripts/skills/aura/ember_of_watch_aura"));
			getContainer().add(::new("scripts/skills/actives/rekindle_skill"));
			getContainer().getActor().getFlags().set("IsPlayerCharacter", true);
			getContainer().getActor().getFlags().set("Cinderwarden", true);
		}
		character_background.onAdded();
		local actor = this.getContainer().getActor().get();
		actor.getFlags().set("IsRotuBackground", true);
	}

	function onAddEquipment()
	{
		// Equipment set in scenario onSpawnAssets — nothing here intentionally.
	}

	// Passive stat bumps — the background itself contributes small, legible
	// numbers. The signature power comes from the trait, not from hidden
	// background math.
	function onUpdate(_properties)
	{
		_properties.Initiative += 5;
		_properties.Bravery    += 3;
	}

	function onAfterUpdate(_properties)
	{
		_properties.DailyWageMult = 0.0;
	}

	// A Cinderwarden who dies never rises as undead. The ember goes out with
	// them — the thing they fought is the thing that would otherwise claim
	// the body. (If Tier IV of the Long Watch is reached, the ember passes
	// to the nearest ally via the capstone — see cinderwarden_trait.onDeath.)
	function onDeath(_fatalityType)
	{
		// MSU's skill_container iterates skills with a single _fatalityType arg.
		// The 4-arg signature is for entities, not skills — using it here threw
		// "wrong number of parameters" on every Cinderwarden death (fixed v2.4.5).
		character_background.onDeath(_fatalityType);
	}

	function onSerialize(_out)
	{
		this.character_background.onSerialize(_out);
	}

	function onDeserialize(_in)
	{
		this.character_background.onDeserialize(_in);
	}
});
