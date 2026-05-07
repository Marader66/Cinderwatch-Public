// The Extinguisher — boss entity for the Western Tower questline (Beat 3).
//
// Lore: a former brother (or sister) of the Cinderwatch who survived the
// plague years, then defected to the Flesh Menders during a crisis of faith.
// Returned to the western twin tower, killed the last warden there, and
// extinguished the ember deliberately. Now serves the Menders as a
// corruption-bearer — the silver ring on their hand is the old order's ring,
// re-forged and tainted.
//
// v2.0: entity ships READY but isn't spawned in scripted combat — Beat 3 of
// the Western Tower quest narrates the confrontation rather than scripting
// it (same pattern Golden Throne used for its partner quest v2.5.0 → v2.5.2
// pipeline). The reckoning event (`cinderwatch_reckoning_event.nut`) drops
// the Vigil Censer into the stash after the narrated fight.
//
// v2.1 (queued): scripted tactical combat wired at the western tower
// location. The Extinguisher spawns here + Flesh Mender retinue.
//
// Equipment note: wields the vanilla `items/weapons/legendary/miasma_flail`
// — FoTN's hook on that class attaches `fotn_miasma_flail_effect`, which
// spews miasma on hit/miss. Thematically perfect: this is exactly what the
// Vigil Censer USED to be before the Cinderwarden recovered and cleansed it.
this.cinderwatch_extinguisher <- this.inherit("scripts/entity/tactical/player", {
	m = {
		IsFemale = false  // set at onInit based on Emperor/Cinderwarden's gender counter-pair
	},

	function create()
	{
		this.player.create();
		this.m.Name         = "The Extinguisher";
		this.m.BloodType    = ::Const.BloodType.Dark;
		this.m.XP           = 3500;  // high kill-XP; this is a chapter-closing boss
		this.m.IsSummoned   = false;
		this.m.IsControlledByPlayer = false;
	}

	// Keep out of post-battle roster / level-up pipelines — one-shot boss.
	function isGuest() { return true; }
	function addXP(_xp, _scale = true) {}

	// Death hook — set the world flag the Reckoning event's resolution branch
	// reads (if we ever wire the scripted-combat path in v2.1). Narrated path
	// in v2.0 sets the same flag from the event's finish handler, so the two
	// code paths converge.
	function onDeath(_killer, _skill, _tile, _fatalityType)
	{
		// v2.1.0 — inject the Vigil Censer into the corpse loot BEFORE
		// the death super-call. This is the thematic moment: the brass
		// remembers what it was, the corruption breaks under the warden's
		// hand. The miasma_flail is IsDroppedAsLoot=false so it stays
		// out — the player picks up only the cleansed version from the
		// corpse-loot UI.
		try {
			local censer = ::new("scripts/items/weapons/named/named_vigil_censer");
			try { censer.m.IsDroppedAsLoot = true; } catch (e) {}
			try { this.m.Items.addToBag(censer); }
			catch (e) {
				try { this.m.Items.equip(censer); } catch (e2) {}
			}
		} catch (e) {
			::logWarning("[mod_cinderwatch] Vigil Censer corpse-inject failed: " + e);
		}

		this.player.onDeath(_killer, _skill, _tile, _fatalityType);
		try {
			if (::World != null) {
				::World.Flags.set("CinderwatchExtinguisherDefeated", true);
			}
		} catch (e) {}
		local name = this.getName();
		::Tactical.EventLog.log("[color=#E07A3A]" + name
			+ " falls. The censer rolls from their hand, still warm.[/color]");
	}

	function onInit()
	{
		this.player.onInit();

		// Hostile faction — Enemy is the standard "generic hostile human"
		// faction BB uses for one-shot scripted-combat bosses. Same value
		// the Reckoning event's Troop spec assigns. Was OrientalBandits
		// (phantom — Const.FactionType.OrientalBandits exists but
		// Const.Faction.OrientalBandits does not) until 2.1.1 fixed it
		// — the entity was never spawned before v2.1.0's scripted combat
		// wire-in so the throw never surfaced.
		this.setFaction(::Const.Faction.Enemy);

		// Pair gender opposite the Cinderwarden — matches the Golden Throne
		// partner quest's identity convention and makes the Extinguisher
		// read as "someone from the player's order, now lost". If the
		// Cinderwarden is female (flag set during intro), the Extinguisher
		// is male, and vice versa.
		local wardenIsFemale = false;
		try {
			if (::World != null) {
				wardenIsFemale = ::World.Flags.get("CinderwardenIsFemale") == true;
			}
		} catch (e) {}
		this.m.IsFemale = wardenIsFemale;  // counter-pair: opposite of warden
		// Hmm, actually — user lock 2026-04-22 on Golden Throne: pair OPPOSITE.
		// Here the Extinguisher is a former member of the order, so they could
		// be EITHER gender regardless of the warden. Flipping to "matching"
		// reads as "a brother / sister like you, who fell." Leaving OPPOSITE
		// (the counter-pair pattern) for v2.0 consistency with partner quest.

		// Use hedge-knight / retired-soldier style background for appearance;
		// the Extinguisher was once a watch member so the silhouette should
		// match the Cinderwarden's general look.
		local bg = this.m.IsFemale ? "legend_shieldmaiden_background" : "hedge_knight_background";
		this.setStartValuesEx([bg], false, 0, false);
		this.setName("The Extinguisher");

		// Stats — boss-tier for Day ~310 fight. Below the Fallen Partner's
		// numbers (that boss was Day ~80; this one is later campaign but
		// still a mortal human, not a mythic figure).
		this.m.Talents = [];
		this.m.Attributes = [];
		for (local i = 0; i < this.Const.Attributes.COUNT; i++) {
			this.m.Talents.push(0);
			this.m.Attributes.push([]);
		}
		local bp = this.m.BaseProperties;
		bp.Hitpoints         = 180;
		bp.Bravery           = 150;
		bp.Stamina           = 140;
		bp.MeleeSkill        = 85;
		bp.RangedSkill       = 30;
		bp.MeleeDefense      = 30;
		bp.RangedDefense     = 20;
		bp.Initiative        = 80;
		bp.Vision            = 6;
		bp.ActionPoints      = 9;
		bp.IsImmuneToPoison         = true;  // corruption immunizes them
		bp.IsImmuneToBleeding       = false;
		bp.IsImmuneToBleedingInjury = false;
		bp.SurvivesAsUndead         = false; // stays dead; doesn't rise

		// Day-310 ROTU champion-tier scaling. Mirrors the Fallen Partner's
		// local-scaling pattern since ROTU's built-in scaler opts out in
		// scenario mode. Same formula, champion difficulty multiplier (1).
		this._applyROTUScaling(bp);

		this.m.CurrentProperties = clone bp;
		this.m.Hitpoints         = bp.Hitpoints;
		this.m.ActionPoints      = bp.ActionPoints;

		// Flags. human + monstrous (for corrupt humans in BB's taxonomy).
		// NOT undead — the Extinguisher is alive-but-corrupted.
		this.getFlags().add("human");
		this.getFlags().add("monstrous");
		this.getFlags().add("corrupt");  // custom flag, future hooks can query

		// Equipment: the Mender's censer flail + medium-heavy armor.
		// This IS the corrupted version of the Vigil Censer — same base
		// class, with FoTN's miasma hook attached via their install. The
		// player will see it spew miasma tiles when the Extinguisher attacks.
		// When the Extinguisher dies, the Reckoning event spawns a CLEAN
		// `named_vigil_censer` into the stash — narratively, the warden
		// picks up the censer and the corruption breaks the moment they
		// touch it.
		local items = this.m.Items;
		try { items.removeAllItems(); } catch (e) {}

		try {
			local flail = ::new("scripts/items/weapons/legendary/miasma_flail");
			try { flail.m.IsDroppedAsLoot = false; } catch (e) {}
			items.equip(flail);
		} catch (e) {
			// Fallback if miasma_flail class isn't accessible for any
			// reason — use a vanilla three-headed flail so the boss still
			// has a weapon. User's running FoTN per the stack CLAUDE.md
			// so this fallback should never trip.
			try {
				items.equip(::new("scripts/items/weapons/three_headed_flail"));
			} catch (e2) {}
		}

		// Body armor: gambeson + hauberk_full. Middle-heavy loadout — fits
		// "ex-soldier, now corrupt" silhouette. No cloak (left the order).
		local body = ::new("scripts/items/legend_armor/cloth/legend_armor_gambeson");
		try { body.m.IsDroppedAsLoot = false; } catch (e) {}
		try {
			body.setUpgrade(::new("scripts/items/legend_armor/chain/legend_armor_hauberk_full"));
		} catch (e) {}
		items.equip(body);

		// Helmet: chain hood under an open kettle hat (same as warden, but
		// this one's kept their face visible to taunt whatever of the order
		// survived). Visual kinship to the Cinderwarden is intentional.
		local head = ::new("scripts/items/legend_helmets/hood/legend_helmet_chain_hood");
		try { head.m.IsDroppedAsLoot = false; } catch (e) {}
		try {
			head.setUpgrade(::new("scripts/items/legend_helmets/helm/legend_helmet_kettle_hat"));
		} catch (e) {}
		items.equip(head);

		// ROTU champion package — racial skill + miniboss flag + champion_glow.
		this._applyROTUChampionPackage();

		// Pale-grey tint — visible marker that this figure is NOT ally and
		// NOT normal. Same palette as the Fallen Partner's fallen tint.
		this._applyCorruptTint();

		// Dramatic combat-start line.
		this.m.StartCombatLine = "You should not have come. The light here is already out.";
	}

	// Local ROTU champion scaler — scenario-mode-safe mirror of
	// Mod_ROTU.Scaling.miniboss(props). Same formula the Golden Throne
	// Fallen Partner uses. difficultyMult = 1 (champion tier).
	function _applyROTUScaling(_bp)
	{
		if (::World == null) return;
		local userMult = 1.0;
		try {
			local setting = ::Mod_ROTU.Mod.ModSettings.getSetting("DifficultyScaling");
			if (setting != null) userMult = setting.getValue() / 100.0;
		} catch (e) {}

		local scale = ::Math.minf(10.0, ::World.getTime().Days / 50.0 * 1.0 * userMult);
		if (scale <= 0) return;

		_bp.MeleeSkill    = ::Math.floor(_bp.MeleeSkill    * (1 + 0.05  * scale));
		_bp.RangedSkill   = ::Math.floor(_bp.RangedSkill   * (1 + 0.05  * scale));
		_bp.MeleeDefense  = ::Math.floor(_bp.MeleeDefense  * (1 + 0.025 * scale));
		_bp.RangedDefense = ::Math.floor(_bp.RangedDefense * (1 + 0.025 * scale));
		_bp.Hitpoints     = ::Math.floor(_bp.Hitpoints     * (1 + 0.2   * scale));
		_bp.Initiative    = ::Math.floor(_bp.Initiative    * (1 + 0.2   * scale));
		_bp.Stamina       = ::Math.floor(_bp.Stamina       * (1 + 0.1   * scale));
		_bp.Bravery       = ::Math.floor(_bp.Bravery       * (1 + 0.2   * scale));
		_bp.FatigueRecoveryRate += scale;

		::logInfo("[mod_cinderwatch] Extinguisher ROTU champion-scaled: day="
			+ ::World.getTime().Days + ", userMult=" + userMult
			+ ", scale=" + scale + ", final HP=" + _bp.Hitpoints);
	}

	function _applyROTUChampionPackage()
	{
		this.m.XP = ::Math.floor(this.m.XP * 1.5);
		this.m.IsMiniboss = true;
		this.m.IsGeneratingKillName = false;

		try {
			if (this.m.Skills.getSkillByID("racial.champion") == null) {
				this.m.Skills.add(::new("scripts/skills/racial/rotu_low_champion_racial"));
			}
		} catch (e) {
			::logWarning("[mod_cinderwatch] Extinguisher champion racial add failed: " + e);
		}

		// Champion glow halo + miniboss bust frame if sprites exist.
		try {
			if (this.hasSprite("before_socket")) {
				local champ = this.getSprite("before_socket");
				champ.setBrush("champion_glow");
				// Sickly green-grey halo instead of red — marks as corrupt
				// rather than bloodborne.
				champ.Color      = this.createColor("#6d8265");
				champ.Saturation = 0.7;
			}
			if (this.hasSprite("miniboss")) {
				this.getSprite("miniboss").setBrush("bust_miniboss");
			}
		} catch (e) {}
	}

	// Pale-grey-green tint. Matches the "corrupt vessel" thematic.
	function _applyCorruptTint()
	{
		local pale = this.createColor("#8A9285");  // muted grey-green
		local layers = [
			"body", "head",
			"armor",
			"armor_layer_chain", "armor_layer_plate", "armor_layer_tabbard",
			"armor_layer_cloak", "armor_layer_cloak_front",
			"armor_upgrade_back", "armor_upgrade_back_top", "armor_upgrade_front",
			"helmet",
			"helmet_helm", "helmet_helm_lower",
			"helmet_top", "helmet_top_lower",
			"helmet_vanity", "helmet_vanity_2", "helmet_vanity_lower"
		];
		foreach (id in layers) {
			if (this.hasSprite(id)) this.getSprite(id).Color = pale;
		}
		this.setDirty(true);
	}

	function onUpdateInjuryLayer()
	{
		this.player.onUpdateInjuryLayer();
		this._applyCorruptTint();
	}

	function onCombatStarted()
	{
		this.player.onCombatStarted();
		local name = this.getName();
		::Tactical.EventLog.log("[color=#E07A3A]" + name
			+ ": \"You should not have come. The light here is already out.\"[/color]");
	}
});
