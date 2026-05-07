// The Vigil Censer — signature reward for the Western Tower questline.
//
// Lore: recovered from the Extinguisher (the corrupted former Cinderwatch
// brother who let the western ember die). The Extinguisher carried a Flesh
// Mender censer flail — a miasma-spewing corruption weapon. In the
// Cinderwarden's hand it is CLEANSED: the brass bowl burns with holy flame
// instead of pouring out poison. The vessel redeemed.
//
// Mechanical identity:
//   - 2H flail, damage profile close to vanilla three_headed_flail
//   - Grants the same censer-kit actives as the vanilla miasma flail
//     (CenserStrike, CenserCastigate, LegendRangedLash) — it's the same
//     tool, used for opposite purpose
//   - CRITICALLY does NOT add fotn_miasma_flail_effect. Inheriting directly
//     from miasma_flail would pull in FoTN's hook that attaches the miasma
//     effect; we avoid that by NOT inheriting from that class, and by only
//     granting the selected actives explicitly.
//   - On equip, adds `vigil_censer_aura` to the wielder — a 2-tile
//     holy-flame ward that makes wielder + nearby allies immune to poison,
//     bleeding, and bleeding injuries
//   - On unequip, removes the aura cleanly
//
// Granted by: scripts/events/events/scenario/cinderwatch_reckoning_event.nut
// on Beat 3 resolution (Day ~310, Extinguisher defeated).
this.named_vigil_censer <- this.inherit("scripts/items/weapons/named/named_weapon", {
	m = {},

	function create()
	{
		this.named_weapon.create();
		this.m.ID          = "weapon.named_vigil_censer";
		this.m.Name        = "The Vigil Censer";
		this.m.NameList    = null;
		this.m.Description = "A brass censer-flail, taken from the one who let the ember die. The chain is heavy. The bowl — once a vessel for corruption's breath — now carries a steady, cleansing flame. What once poured out poison now holds back the dark. Carry it with a steady hand.";
		this.m.Categories  = "Flail, Polearm, Two-Handed, Named, Holy";
		// Dual-class: censer-flail with a long-pole haft, so perks from
		// BOTH FlailTree AND PolearmTree apply. Bitmask both WeaponType
		// flags so the engine's perk-applies-to-this-weapon check resolves
		// either way. Set 2026-05-06 per Marader directive.
		this.m.WeaponType  = this.Const.Items.WeaponType.Flail | this.Const.Items.WeaponType.Polearm;
		this.m.SlotType    = this.Const.ItemSlot.Mainhand;
		this.m.BlockedSlotType = this.Const.ItemSlot.Offhand;
		this.m.ItemType    = this.Const.Items.ItemType.Named
			| this.Const.Items.ItemType.Weapon
			| this.Const.Items.ItemType.MeleeWeapon
			| this.Const.Items.ItemType.TwoHanded;
		this.m.IsAgainstShields = false;
		this.m.IsAoE            = false;
		this.m.AddGenericSkill  = true;
		this.m.ShowQuiver       = false;
		this.m.ShowArmamentIcon = true;
		this.m.Value         = 5500;  // legendary-tier, slightly above partner sword
		this.m.Condition     = 80.0;
		this.m.ConditionMax  = 80.0;
		this.m.StaminaModifier = -8;  // heavy — it IS a censer flail
		this.m.RegularDamage      = 50;
		this.m.RegularDamageMax   = 75;
		this.m.ArmorDamageMult    = 1.1;   // flails crush armor well
		this.m.DirectDamageMult   = 0.35;
		this.m.ChanceToHitHead    = 25;    // flails climb around shields

		// Visuals: use vanilla three-headed flail sprites. Not ideal — we'd
		// want a holy-tinted version — but vanilla-safe until custom art lands.
		this.m.Variants = [1, 2, 3];
		this.setVariant(this.m.Variants[this.Math.rand(0, this.m.Variants.len() - 1)]);
		this.randomizeValues();
	}

	function updateVariant()
	{
		this.m.Icon         = "weapons/melee/named_three_headed_flail_0" + this.m.Variant + "_70x70.png";
		this.m.IconLarge    = "weapons/melee/named_three_headed_flail_0" + this.m.Variant + ".png";
		this.m.ArmamentIcon = "icon_named_three_headed_flail_0" + this.m.Variant;
	}

	// On equip, grant the full censer-kit + the Vigil aura.
	// The active-skill grants mirror what Legends attaches to the vanilla
	// miasma_flail — same weapon class, same moveset. The difference is
	// the aura (added below) instead of the miasma effect.
	function onEquip()
	{
		this.named_weapon.onEquip();

		// Censer moveset — only added if Legends is present. Guarded so the
		// item still works on hypothetical non-Legends installs (though
		// Legends is a declared baseline dep for this scenario).
		// v2.4.8 — CenserCastigate dropped; it's the miasma-cloud attack
		// from the vanilla miasma flail kit and reintroduces corruption
		// the Vigil Censer is supposed to have shed. CenserStrike (chain
		// swing) + LegendRangedLash (ranged extension) keep the censer
		// kit's flavor without the cloud.
		if ("Legends" in ::getroottable() && "Actives" in ::Legends) {
			try { ::Legends.Actives.grant(this, ::Legends.Active.CenserStrike); } catch (e) {}
			try { ::Legends.Actives.grant(this, ::Legends.Active.LegendRangedLash); } catch (e) {}
		}

		// The Vigil Censer's defining property — the cleansing ward.
		// Applied as a skill on the weapon itself (this) rather than the
		// wielder, so BB's weapon-skill system removes it on unequip.
		try { this.addSkill(::new("scripts/skills/aura/vigil_censer_aura")); } catch (e) {}
	}

	// Bonus damage against Flesh Mender / corrupt enemies. Falls back to any
	// actor flagged `monstrous` which covers the flesh-golem family and
	// related corruption entities without needing a custom flag.
	function onAnySkillUsed(_skill, _targetEntity, _properties)
	{
		this.named_weapon.onAnySkillUsed(_skill, _targetEntity, _properties);
		if (_targetEntity == null) return;
		if (_skill == null || !_skill.isAttack()) return;
		local flags = _targetEntity.getFlags();
		if (flags != null && (flags.has("monstrous") || flags.has("undead") || flags.has("beast"))) {
			_properties.DamageRegularMult *= 1.15;
			_properties.DamageArmorMult   *= 1.10;
		}
	}

	function getTooltip()
	{
		local ret = this.named_weapon.getTooltip();
		ret.push({
			id = 20, type = "text", icon = "ui/icons/special.png",
			text = "Wielder + allies within [color=" + ::Const.UI.Color.PositiveValue + "]2 tiles[/color] are immune to poison, bleeding, and bleeding injuries."
		});
		ret.push({
			id = 21, type = "text", icon = "ui/icons/damage_dealt.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+15%[/color] damage and [color=" + ::Const.UI.Color.PositiveValue + "]+10%[/color] armour damage against corrupt, undead, and beast foes."
		});
		ret.push({
			id = 22, type = "text", icon = "ui/icons/morale.png",
			text = "Morale penalties on those within the ward reduced by [color=" + ::Const.UI.Color.PositiveValue + "]20%[/color]."
		});
		return ret;
	}
});
