local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);


local WorkbenchLibrary = {}

WorkbenchLibrary.PolishDuration = 3600;
WorkbenchLibrary.PolishRangeBase = {Min=0.01; Max=0.2;};
--==

function WorkbenchLibrary.GetSkipCost(timeLeft)
	return math.clamp(math.ceil(timeLeft/60)*1, 5, 9999);
	--return math.clamp(math.ceil(timeLeft/3600)*5, 5, 9999);
end

function WorkbenchLibrary.CalculateCost(library, level)
	level = level and level+1 or 1;
	return math.floor(library.BaseCost+((library.MaxCost-library.BaseCost)*math.clamp(level/library.MaxLevel, 0, 1)^2.718281));
end

function WorkbenchLibrary.StorageCost(storageId, size, page)
	if storageId:match("Safehouse") then
		return math.clamp(5+((size-24)*(page or 1)), 5, 100);
		--return math.clamp(5+((size-24)*1), 5, 25);
		
	elseif storageId:match("dufflebag") then
		return math.clamp(10+((size-5)*1), 10, 15);
		
	elseif storageId:match("ammopouch") then
		return math.clamp(5+((size-5)*1), 5, 10);
		
	elseif storageId:match("Freezer") then
		return math.clamp(10+((size-10)*2), 10, 15);
		
	end
	return 9999999999;
end

function WorkbenchLibrary.CalculatePerksSpent(storageItem, library, isPremium)
	local isMaxed = #library.Upgrades > 0;
	local perks = 0;
	
	for a=1, #library.Upgrades do
		local upgradeData = library.Upgrades[a];
		local itemUpgradeLvl = (storageItem.Values[upgradeData.DataTag] or 0);
		
		if itemUpgradeLvl < upgradeData.MaxLevel then
			isMaxed = false;
		end
		
		for a=0, itemUpgradeLvl-1 do
			perks = perks + WorkbenchLibrary.CalculateCost(upgradeData, a);
		end
	end
	perks = math.clamp(isPremium and math.ceil(perks * 1) or math.floor(perks * 0.9), 0, math.huge);
	return perks, isMaxed;
end

WorkbenchLibrary.CategorySorting = {
	["Medical Supplies"]=1;
	["Tools"]=2;
	["Keys"]=10;
	["Resource Packages"]=20;
	["Commodities"]=30;
	
	["Elemental Mods"]=40;
	["Health Mods"]=50;
	["Armor Mods"]=60;
	["Rare Mods"]=70;
	["Damage Mods"]=80;
	["Fire Rate Mods"]=90;
	["Reload Speed Mods"]=100;
	["Ammo Capacity Mods"]=110;
	
	["Weapons"]=150;
	["Miscellaneous"]=200;
};

WorkbenchLibrary.WeaponTypeSorting = {
	["Pistol"]=1;
	["Submachine gun"]=2;
	["Shotgun"]=3;
	["Rifle"]=4;
	["Sniper"]=5;
	["Heavy machine gun"]=6;
	["Pyrotechnic"]=7;
	["Explosive"]=8;
	["Bow"]=9;
}

local GenericTraits = {
	MaxAmmoLimit={Rarity=1; Stat="MaxAmmoLimit"; Value={Min=40; Max=100;}; Add=true;};
}

WorkbenchLibrary.ItemUpgrades={
	["p250"]={
		Type={"Pistol"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=30;}; Add=true;};
		};
	};
	["dualp250"]={
		Tier=2;
		Type={"Pistol"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=10;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=30;}; Add=true;};
		};
	};
	["cz75"]={
		Type={"Pistol"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=3; Max=7;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=30;}; Add=true;};
		};
	};
	["deagle"]={
		Type={"Pistol"};
		Tier=3;
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=5; Max=15;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=4;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=10; Max=30;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=5; Max=10;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=20;}; Add=true;};
		};
	};
	["tec9"]={
		Type={"Pistol"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=3; Max=10;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=3;};};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=2; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=5; Max=25;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=20;}; Add=true; };
		};
	};
	["m9legacy"]={
		Tier=2;
		Type={"Pistol"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=25; Max=50;}; Add=true; };
		};
	};
	["mp5"]={
		Type={"Submachine gun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=35; Max=60;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=30;}; Add=true; };
		};
	};
	["mp7"]={
		Type={"Submachine gun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=15; Max=45;}; Add=true; };
		};
	};
	["xm1014"]={
		Type={"Shotgun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=10;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=3;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=25; Max=50;}; Add=true; };
		};
	};
	["sawedoff"]={
		Type={"Shotgun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=10;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=25; Max=50;}; Add=true; };
		};
	};
	["mariner590"]={
		Tier=2;
		Type={"Shotgun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=10;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=4;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=25; Max=50;}; Add=true; };
		};
	};
	["m4a4"]={
		Type={"Rifle"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=5;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=15; Max=35;}; Add=true; };
		};
	};
	["ak47"]={
		Type={"Rifle"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=5;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=15; Max=35;}; Add=true; };
		};
	};
	["awp"]={
		Type={"Sniper"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=10;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1/3; Stat="FocusDuration"; Value={Min=5; Max=25;}; };
		};
	};
	["minigun"]={
		Type={"Heavy machine gun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1/3; Stat="SpinUpTime"; Value={Min=5; Max=25;}; Negative=true;};
		};
	};
	["flamethrower"]={
		Type={"Flamethrower"; "Pyrotechnic"; "Launcher";};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=20;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=10; Max=50;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="ProjectileVelocity"; Value={Min=5; Max=25;};};
			{Rarity=1/3; Stat="ProjectileLifeTime"; Value={Min=15; Max=50;}; Int=true;};
		};
	};
	["grenadelauncher"]={
		Tier=2;
		Type={"Explosive"; "Launcher"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=35;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="FocusWalkSpeedReduction"; Value={Min=20; Max=50;};};
			{Rarity=1/3; Stat="ExplosionRadius"; Value={Min=5; Max=20;}; Int=true;};
		};
	};
	["revolver454"]={
		Tier=2;
		Type={"Pistol"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=25; Max=50;}; Add=true; };
		};
	};
	["czevo3"]={
		Tier=2;
		Type={"Submachine gun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=15; Max=40;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=15; Max=45;}; Add=true; };
		};
	};
	["fnfal"]={
		Tier=2;
		Type={"Rifle"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=5;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=15; Max=35;}; Add=true; };
		};
	};
	["tacticalbow"]={
		Tier=3;
		Type={"Bow"; "Launcher"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;};};
			{Rarity=1/2; Stat="FocusDuration"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="FocusWalkSpeedReduction"; Value={Min=20; Max=50;};};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=4; Max=10;}; Add=true; }; --Value={Min=15; Max=35;};
		};
	};
	["desolatorheavy"]={
		Tier=2;
		Type={"Heavy machine gun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=5; Max=12;}; Add=true; };
			{Rarity=1/3; Stat="Inaccuracy"; Value={Min=1; Max=10;}; Negative=true;};
		};
	};
	["rec21"]={
		Tier=2;
		Type={"Sniper"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=10;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1/3; Stat="FocusDuration"; Value={Min=5; Max=25;}; Negative=true;};
		};
	};
	["at4"]={
		Tier=3;
		Type={"Explosive"; "Launcher"; "Rocket"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1/4; Stat="ReloadSpeed"; Value={Min=5; Max=35;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="FocusWalkSpeedReduction"; Value={Min=20; Max=50;};};
			{Rarity=1; Stat="ExplosionRadius"; Value={Min=1; Max=6;}; Int=true;};
		};
	};
	["sr308"]={
		Tier=3;
		Type={"Rifle"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FireRate"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=5;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1/3; Stat="CritChance"; Value={Min=1; Max=5;}; Add=true;};
		};
	};
	["vectorx"]={
		Tier=4;
		Type={"Submachine gun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=10;}; Negative=true;};
			{Rarity=1/2; Stat="HeadshotMultiplier"; Value={Min=15; Max=45;}; Add=true; };
			{Rarity=1/3; Stat="CritChance"; Value={Min=1; Max=5;}; Add=true;};
		};
	};
	["rusty48"]={
		Tier=4;
		Type={"Shotgun"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=1; Max=10;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="Inaccuracy"; Value={Min=1; Max=4;}; Negative=true;};
			{Rarity=1/2; Stat="HeadshotMultiplier"; Value={Min=25; Max=50;}; Add=true; };
			{Rarity=1/3; Stat="CritChance"; Value={Min=1; Max=3;}; Add=true;};
		};
	};
	["arelshiftcross"]={
		Tier=4;
		Type={"Bow"; "Bolt"; "Launcher"};
		TraitStats={
			{Rarity=1/3; Stat="Damage";  Value={Min=1; Max=5;}; };
			{Rarity=1/2; Stat="FocusDuration"; Value={Min=1; Max=5;}; Negative=true;};
			{Rarity=1; Stat="ReloadSpeed"; Value={Min=5; Max=25;}; Negative=true;};
			GenericTraits.MaxAmmoLimit;
			{Rarity=1; Stat="FocusWalkSpeedReduction"; Value={Min=20; Max=50;};};
			{Rarity=1/3; Stat="HeadshotMultiplier"; Value={Min=10; Max=20;}; Add=true; };
		};
	};
	
	
	--== Melee
	["survivalknife"]={
		Type={"Edged Melee"; "Melee"};
	};
	["machete"]={
		Type={"Edged Melee"; "Melee"};
	};
	["spikedbat"]={
		Type={"Blunt Melee"; "Melee"};
	};
	["crowbar"]={
		Type={"Blunt Melee"; "Melee"};
	};
	["sledgehammer"]={
		Type={"Blunt Melee"; "Melee"};
	};
	["pickaxe"]={
		Type={"Pointed Melee"; "Melee"};
	};
	["broomspear"]={
		Type={"Pointed Melee"; "Melee"};
	};
	["jacksscythe"]={
		Type={"Edged Melee"; "Melee"};
	};
	["naughtycane"]={
		Type={"Blunt Melee"; "Melee"};
	};
	["chainsaw"]={
		Tier=2;
		Type={"Edged Melee"; "Melee"};
	};
	["shovel"]={
		Tier=2;
		Type={"Blunt Melee"; "Melee"};
	};
	["inquisitorssword"]={
		Type={"Edged Melee"; "Melee"};
		SkinWear={
			Wear={Min=0.000001; Max=0.01;};
		};
	};
	["fireaxe"]={
		Tier=2;
		Type={"Edged Melee"; "Melee"};
	};
	["keytar"]={
		Tier=2;
		Type={"Edged Melee"; "Melee"};
	};
	["boomerang"]={
		Type={"Pointed Melee"; "Melee"};
	};
	
	--== Clothing
	
	-- Head
	["cowboyhat"]={
		Type={"Head"};
	};
	["gasmask"]={
		Type={"Head"};
	};
	["cultisthood"]={
		Type={"Head"};
	};
	["onyxhoodiehood"]={
		Type={"Head"};
	};
	["disguisekit"]={
		Type={"Head"};
	};
	["nvg"]={
		Type={"Head"};
	};
	["strawhat"]={
		Type={"Head"};
	};
	["zriceraskull"]={
		Type={"Head"};
	};
	["hazmathood"]={
		Type={"Head"};
	};
	["tophat"]={
		Type={"Head"};
	};
	["clownmask"]={
		Type={"Head"};
	};
	["divinggoggles"]={
		Type={"Head"};
	};
	["balaclava"]={
		Type={"Head"};
	};
	["skullmask"]={
		Type={"Head"};
	};
	["maraudersmask"]={
		Type={"Head"};
	};
	["clothbagmask"]={
		Type={"Head"};
	};
	["hardhat"]={
		Type={"Head"};
	};
	["fedora"]={
		Type={"Head"};
	};
	["santahat"]={
		Type={"Head"};
	};
	["greensantahat"]={
		Type={"Head"};
	};
	["bunnymanhead"]={
		Type={"Head"};
	};
	["jackolantern"]={
		Type={"Head"};
	};
	
	
	-- Chest
	["labcoat"]={
		Type={"Chest"};
	};
	["prisonshirt"]={
		Type={"Chest"};
	};
	["onyxhoodie"]={
		Type={"Chest"};
	};
	["greytshirt"]={
		Type={"Chest"};
	};
	["xmassweater"]={
		Type={"Chest"};
	};
	["plankarmor"]={
		Type={"Chest"};
	};
	["scraparmor"]={
		Type={"Chest"};
	};
	["highvisjacket"]={
		Type={"Chest"};
	};
	["nekrostrench"]={
		Type={"Chest"};
	};
	["tirearmor"]={
		Type={"Chest"};
	};
	["apron"]={
		Type={"Chest"};
	};
	
	-- Gloves
	["leathergloves"]={
		Type={"Gloves"};
	};
	["armwraps"]={
		Type={"Gloves";};
	};
	["vexgloves"]={
		Type={"Gloves"};
	};
	
	-- Pants
	["prisonpants"]={
		Type={"Pants"};
	};
	
	-- Shoes
	["militaryboots"]={
		Type={"Shoes"};
	};
	["brownleatherboots"]={
		Type={"Shoes"};
	};
	
	-- Storage
	["dufflebag"]={
		Type={"Storage"};
	};
	["survivorsbackpack"]={
		Type={"Storage"};
	};

	-- Utility Wear
	["brownbelt"]={
		Type={"Utility Wear"};
	};
	["mercskneepads"]={
		Type={"Utility Wear"};
	};
	["watch"]={
		Type={"Utility Wear"};
	};
	["divingsuit"]={
		Type={"Body"; "Utility Wear"};
	};
	["inflatablebuoy"]={
		Type={"Utility Wear"};
	};
};

WorkbenchLibrary.ItemAppearance={
	["p250"]={
		ToolGripModel="p250";
		
		ToolGrip={}
	};
	["cz75"]={
		ToolGripModel="cz75";
		ToolGrip={};
	};
	["tec9"]={
		ToolGripModel="tec9";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["deagle"]={
		ToolGripModel="deagle";
		ToolGrip={};
	};
	["dualp250"]={
		LeftToolGripModel="p250";
		LeftToolGripOffset=CFrame.new(0, 0, 1) * CFrame.Angles(math.rad(45), 0, 0);
		LeftToolGrip={};
		RightToolGripModel="p250";
		RightToolGripOffset=CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(-45), math.rad(180), 0);
		RightToolGrip={}
	};
	["xm1014"]={
		ToolGripModel="xm1014";
		ToolGripOffset=CFrame.new(-1.5, 0, 0);
		ToolGrip={};
	};
	["sawedoff"]={
		ToolGripModel="sawedoff";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={};
	};
	["mp5"]={
		ToolGripModel="mp5";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={};
	};
	["mp7"]={
		ToolGripModel="mp7";
		ToolGrip={};
	};
	["m4a4"]={
		ToolGripModel="m4a4";
		ToolGrip={};
	};
	["ak47"]={
		ToolGripModel="ak47";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={};
	};
	["awp"]={
		ToolGripModel="awp";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(0));
		ToolGrip={};
	};
	["minigun"]={
		ToolGripModel="minigun";
		ToolGripOffset=CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(0));
		ToolGrip={};
	};
	["flamethrower"]={
		ToolGripModel="flamethrower";
		ToolGripOffset=CFrame.new(1, 0, 0) * CFrame.Angles(0, math.rad(90), 0);
		ToolGrip={};
	};
	["grenadelauncher"]={
		ToolGripModel="grenadelauncher";
		ToolGripOffset=CFrame.new(0, 0, -1) * CFrame.Angles(0, math.rad(90), 0);
		ToolGrip={};
	};
	["m9legacy"]={
		ToolGripModel="m9legacy";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0,0);
		ToolGrip={};
	};
	["revolver454"]={
		ToolGripModel="revolver454";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0,0,0);
		ToolGrip={};
	};
	["mariner590"]={
		ToolGripModel="mariner590";
		ToolGrip={};
	};
	["czevo3"]={
		ToolGripModel="czevo3";
		ToolGrip={};
	};
	["fnfal"]={
		ToolGripModel="fnfal";
		ToolGrip={};
	};
	["tacticalbow"]={
		LeftToolGripModel="tacticalbow";
		LeftToolGripOffset=CFrame.new(0, 0, 0);
		LeftToolGrip={};
	};
	["desolatorheavy"]={
		ToolGripModel="desolatorheavy";
		ToolGrip={};
	};
	["rec21"]={
		ToolGripModel="rec21";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={};
	};
	["at4"]={
		ToolGripModel="at4";
		ToolGrip={};
	};
	["sr308"]={
		ToolGripModel="sr308";
		ToolGrip={};
	};
	["vectorx"]={
		ToolGripModel="vectorx";
		ToolGrip={};
	};
	["rusty48"]={
		ToolGripModel="rusty48";
		ToolGripOffset=CFrame.new(0, 0, 1.7);
		ToolGrip={};
	};
	["arelshiftcross"]={
		ToolGripModel="arelshiftcross";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={};
	};
	
	
	--== Melee
	["survivalknife"]={
		ToolGripModel="survivalknife";
		ToolGripOffset=CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90));
		ToolGrip={};
	};
	["machete"]={
		ToolGripModel="machete";
		ToolGripOffset=CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["spikedbat"]={
		ToolGripModel="spikedbat";
		ToolGripOffset=CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["naughtycane"]={
		ToolGripModel="naughtycane";
		ToolGripOffset=CFrame.new(0, -0.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["crowbar"]={
		ToolGripModel="crowbar";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["sledgehammer"]={
		ToolGripModel="sledgehammer";
		ToolGripOffset=CFrame.new(0, -1.3, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["pickaxe"]={
		ToolGripModel="pickaxe";
		ToolGripOffset=CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["broomspear"]={
		ToolGripModel="broomspear";
		ToolGripOffset=CFrame.new();
		ToolGrip={};
	};
	["jacksscythe"]={
		ToolGripModel="jacksscythe";
		ToolGripOffset=CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["chainsaw"]={
		ToolGripModel="chainsaw";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["shovel"]={
		ToolGripModel="shovel";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["inquisitorssword"]={
		ToolGripModel="inquisitorssword";
		ToolGripOffset=CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["fireaxe"]={
		ToolGripModel="fireaxe";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["boomerang"]={
		ToolGripModel="boomerang";
		ToolGripOffset=CFrame.new();
		ToolGrip={};
	};
	
	
	--== Tools
	["wateringcan"]={
		ToolGripModel="wateringcan";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["lantern"]={
		ToolGripModel="lantern";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["spotlight"]={
		ToolGripModel="spotlight";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["musicbox"]={
		ToolGripModel="musicbox";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["binoculars"]={
		ToolGripModel="binoculars";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
	["keytar"]={
		ToolGripModel="keytar";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={};
	};
};

WorkbenchLibrary.PurchaseReplies = setmetatable({
	Success = 0;
	InsufficientCurrency = 1;
	TooFar = 2;
	InvalidUpgrade = 3;
	Failed = 4;
	TooFrequentRequest = 5;
}, {__index={
	"Not enough $Currency.";
	"You are too far from workbench.";
	"Invalid Upgrade.";
	"Failed";
	"Too Frequent Request.";
};});

WorkbenchLibrary.DeconstructModReplies = setmetatable({
	Success = 0;
	TooFrequentRequest = 1;
	TooFar = 2;
	InvalidItem = 3;
	BenchFull = 4;
	InventoryFull = 5;
	HasMods = 6;
	MaxedPerks = 7;
}, {__index={
	"Please try again after 1 second.";
	"You are too far from workbench.";
	"Invalid Item.";
	"The workbench is full.";
	"Inventory is full.";
	"Cannot deconstruct modded item.";
	"Maxed Perks.";
};});

WorkbenchLibrary.PolishToolReplies = setmetatable({
	Success = 0;
	TooFrequentRequest = 1;
	TooFar = 2;
	InvalidItem = 3;
	BenchFull = 4;
	InventoryFull = 5;
	HasMods = 6;
	InsufficientResources = 7;
	InsufficientPerks = 8;
}, {__index={
	"Please try again after 1 second.";
	"You are too far from workbench.";
	"Invalid Item.";
	"The workbench is full.";
	"Inventory is full.";
	"Cannot polish modded item.";
	"Insufficient resources.";
	"Insufficient Perks.";
};});

WorkbenchLibrary.BlueprintReplies = setmetatable({
	Success = 0;
	InsufficientCurrency = 1;
	TooFar = 2;
	InvalidBlueprint = 3;
	TooFrequentRequest = 4;
	BlueprintLocked = 5;
	InventoryFull = 6;
	ModsFull = 7;
	WorkbenchFull = 8;
	Disabled = 9;
	UnknownErr=10;
}, {__index={
	"Missing blueprint requirements.";
	"You are too far from the workbench.";
	"Invalid blueprint.";
	"Please try again after 1 second.";
	"You haven't unlocked this blueprint.";
	"Inventory is full.";
	"Mod storage is full.";
	"The workbench is full.";
	"Blueprint is Disabled";
	"Unknown Issue";
};});

return WorkbenchLibrary;