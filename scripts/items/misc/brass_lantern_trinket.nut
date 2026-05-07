// brass_lantern_trinket — the Cinderwarden's signature starting item.
//
// Lives in the Legends Accessory slot so it doesn't collide with Offhand
// (shields, torches, trap kits). Passive effects only — no active skill
// container — keeps the mechanical identity of Rekindle (one skill, in one
// place) uncluttered.
//
// Effects:
//   +1 Vision
//   +5 Bravery (the comfort of carrying the light)
//   +1 FatigueRecoveryRate
//
// Not dropped on death. Inherited-of-Flame's handoff ignores this item —
// the ember the trait represents is the INSTITUTIONAL fire, not this
// specific physical object. In the fiction the Cinderwarden has many
// replacement lanterns; the order's lantern is the one left at the tower.
this.brass_lantern_trinket <- this.inherit("scripts/items/accessory/accessory", {
	m = {},
	function create()
	{
		this.accessory.create();
		this.m.ID              = "accessory.brass_lantern";
		this.m.Name            = "Brass Lantern";
		this.m.Description     = "A small brass watch-lantern, kept polished beyond the tower's means. It never quite burns out — the Cinderwatch order taught its members how to keep a flame alive on a long road.";
		this.m.SlotType        = this.Const.ItemSlot.Accessory;
		this.m.IsDroppedAsLoot = false;
		this.m.ShowOnCharacter = false;
		this.m.IconLarge       = "";
		// v1.3.3: was `tools/torch.png` which doesn't exist (log showed
		// "Unable to open file" error at item render). BB prefixes
		// `gfx/ui/items/` so the resolved path `gfx/ui/items/tools/torch.png`
		// isn't a real vanilla asset — the tool-folder filenames all carry
		// `_NN_70x70` suffixes (see legend_unhold_throwing_net, smoke_bomb,
		// etc). Swapped to `accessory/oms_amphora_full.png` — a Legends
		// accessory brass-vessel that thematically reads as "filled
		// ember-vessel" close enough to "brass lantern" until custom art
		// lands. Confirmed present in Legends assets.
		this.m.Icon            = "accessory/oms_amphora_full.png";
		this.m.Sprite          = "";
		this.m.Value           = 300;
	}

	function getTooltip()
	{
		local result = [
			{ id = 1, type = "title",       text = this.getName() },
			{ id = 2, type = "description", text = this.getDescription() }
		];
		result.push({ id = 66, type = "text", text = this.getValueString() });

		if (this.getIconLarge() != null) {
			result.push({ id = 3, type = "image", image = this.getIconLarge(), isLarge = true });
		} else {
			result.push({ id = 3, type = "image", image = this.getIcon() });
		}

		result.push({
			id = 10, type = "text", icon = "ui/icons/vision.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+1[/color] Vision"
		});
		result.push({
			id = 11, type = "text", icon = "ui/icons/bravery.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Bravery"
		});
		result.push({
			id = 12, type = "text", icon = "ui/icons/fatigue.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+1[/color] Fatigue Recovery Rate"
		});
		return result;
	}

	function onUpdateProperties(_properties)
	{
		this.accessory.onUpdateProperties(_properties);
		_properties.Vision               += 1;
		_properties.Bravery              += 5;
		_properties.FatigueRecoveryRate  += 1;
	}
});
