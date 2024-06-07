local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);


local WorkbenchLibrary = {}


WorkbenchLibrary.PolishCost = 100;
WorkbenchLibrary.PolishPremiumCost = 50;

WorkbenchLibrary.PolishLimit = 0.15;

WorkbenchLibrary.PolishRangeBase = {Min=0.05; Max=0.1;};
--==

function WorkbenchLibrary.GetSkipCost(timeLeft)
	return math.clamp(math.ceil(timeLeft/60)*1, 5, 9999);
	--return math.clamp(math.ceil(timeLeft/3600)*5, 5, 9999);
end

function WorkbenchLibrary.CalculateCost(library, level)
	level = level and level+1 or 1;
	return math.floor(library.BaseCost+((library.MaxCost-library.BaseCost)*math.clamp(level/library.MaxLevel, 0, 1)^2.718281));
end

function WorkbenchLibrary.StorageCost(storageId, size)
	if storageId:match("Safehouse") then
		return math.clamp(5+((size-24)*1), 5, 25);
		
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
		SkinWear={
			Wear={Min=0.000001; Max=0.43;};
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
		SkinWear={
			Wear={Min=0.000001; Max=0.43;};
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
		SkinWear={
			Wear={Min=0.000001; Max=0.43;};
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
		SkinWear={
			Wear={Min=0.32; Max=0.999999;};
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
		SkinWear={
			Wear={Min=0.000001; Max=0.59;};
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
		SkinWear={
			Wear={Min=0.000001; Max=0.4;};
		};
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
		
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Body";}; --
			--Magazine={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Slide={		DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Barrel={		DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Chamber={		DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--FrontSight={		DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Grips={		DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Hammer={		DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Lock={		DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--MagEject={		DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Rails={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--RearSight={		DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--SightDot={		DefaultColor=Color3.fromRGB(0, 100, 0);}; --
			--SlideLock={		DefaultColor=Color3.fromRGB(60, 60, 60);}; -- 
			--Trigger={		DefaultColor=Color3.fromRGB(60, 60, 60);}; --
		}
	};
	["cz75"]={
		ToolGripModel="cz75";
		ToolGrip={
			--Barrel={	DefaultColor=Color3.fromRGB(120, 120, 120);	PartName="Body";}; --
			--Grip={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Hammer={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Handle={		DefaultColor=Color3.fromRGB(40, 40, 40);}; --
			--MagReleaser={	DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Magazine={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Magazine2={	DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Secondary Magazine";}; --
			--Safety={	DefaultColor=Color3.fromRGB(255, 0, 0);}; --
			--SafetyLock={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Screws={	DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Slide={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--SlideLock={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Trigger={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
		};
	};
	["tec9"]={
		ToolGripModel="tec9";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Barral={	DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Barrel";}; --
			--Body={	DefaultColor=Color3.fromRGB(40, 40, 40);}; --
			--Bolt={		DefaultColor=Color3.fromRGB(100, 100, 100);}; --
			--Chamber={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Grip={	DefaultColor=Color3.fromRGB(50, 50, 50);}; --  
			--Handle={	DefaultColor=Color3.fromRGB(40, 40, 40);}; --
			--MagRelease={	DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Magazine={	DefaultColor=Color3.fromRGB(60, 60, 60);}; --
			--Screws={	DefaultColor=Color3.fromRGB(120, 120, 120);}; --
			--Trigger={	DefaultColor=Color3.fromRGB(120, 120, 120);}; --
		};
	};
	["deagle"]={
		ToolGripModel="deagle";
		ToolGrip={
			--Barrel={	DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Detail={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Grip={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Hammer={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Handle={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--MagRelease={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Magazine={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Red={			DefaultColor=Color3.fromRGB(255, 0, 0);};
			--Safety={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Screws={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Slide={			DefaultColor=Color3.fromRGB(40, 40, 40);};
			--SlideLock={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Trigger={		DefaultColor=Color3.fromRGB(100, 100, 100);};
		};
	};
	["dualp250"]={
		LeftToolGripModel="p250";
		LeftToolGripOffset=CFrame.new(0, 0, 1) * CFrame.Angles(math.rad(45), 0, 0);
		LeftToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Body";};
			--Magazine={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Slide={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Barrel={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Chamber={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--FrontSight={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Grips={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Hammer={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Lock={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--MagEject={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Rails={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--RearSight={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--SightDot={		DefaultColor=Color3.fromRGB(0, 100, 0);};
			--SlideLock={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Trigger={		DefaultColor=Color3.fromRGB(60, 60, 60);};
		};
		RightToolGripModel="p250";
		RightToolGripOffset=CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(-45), math.rad(180), 0);
		RightToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Body";};
			--Magazine={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Slide={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Barrel={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Chamber={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--FrontSight={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Grips={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Hammer={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Lock={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--MagEject={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Rails={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--RearSight={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--SightDot={		DefaultColor=Color3.fromRGB(0, 100, 0);};
			--SlideLock={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Trigger={		DefaultColor=Color3.fromRGB(60, 60, 60);};
		}
	};
	["xm1014"]={
		ToolGripModel="xm1014";
		ToolGripOffset=CFrame.new(-1.5, 0, 0);
		ToolGrip={
			--Barrel={	DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Body={	DefaultColor=Color3.fromRGB(100, 100, 100);};
			--FrontSight={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Gauge={	DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Handle={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--MagazineTop={	DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Pump={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Rails={	DefaultColor=Color3.fromRGB(100, 100, 100);};
			--RearSight={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--SightDot={	DefaultColor=Color3.fromRGB(0, 255, 0);};
			--Slide={	DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Stock={	DefaultColor=Color3.fromRGB(100, 100, 100);};
			--StockGrip={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Trigger={	DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Tube={	DefaultColor=Color3.fromRGB(100, 100, 100); PartName="Barrel 2";};
		};
	};
	["sawedoff"]={
		ToolGripModel="sawedoff";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={
			--Barral={	DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Barrels";};
			--Body={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Chamber={	DefaultColor=Color3.fromRGB(52, 35, 19);};
			--Grip={		DefaultColor=Color3.fromRGB(52, 35, 19);};
			--Handle={	DefaultColor=Color3.fromRGB(52, 35, 19);};
			--HandleGrip={	DefaultColor=Color3.fromRGB(175, 148, 131);};
			--Lever={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Screws={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Sight={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Stock={	DefaultColor=Color3.fromRGB(177, 119, 64);};
		};
	};
	["mp5"]={
		ToolGripModel="mp5";
		ToolGripOffset=CFrame.new(0, 0, -0.5);
		ToolGrip={
			--Body={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Chamber={		DefaultColor=Color3.fromRGB(200, 200, 200);};
			--ChargingHandle={DefaultColor=Color3.fromRGB(163, 162, 165);	PartName="Charging Handle";};
			--Flashlight={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--FlashlightNeon={		DefaultColor=Color3.fromRGB(163, 162, 165); PartName="Flashlight Interior";};
			--Grip={			DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Grips";};
			--Handle={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--MagRelease={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--MagWell={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Magazine={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Stock={			DefaultColor=Color3.fromRGB(60, 60, 60);};
			--StockEnd={			DefaultColor=Color3.fromRGB(60, 60, 60);};
			--StockStart={			DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Switch={			DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Trigger={			DefaultColor=Color3.fromRGB(163, 162, 165);};
		};
	};
	["mp7"]={
		ToolGripModel="mp7";
		ToolGrip={
			--BackPlate={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Barrel={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Body={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--ChargingHandle={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Cover={		DefaultColor=Color3.fromRGB(80, 80, 80);};
			--GripHandle={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Handle={		DefaultColor=Color3.fromRGB(50, 50, 50);};
			--Magazine={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Rails={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Receiver={		DefaultColor=Color3.fromRGB(80, 80, 80);};
			--Screws={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Sights={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Slide={		DefaultColor=Color3.fromRGB(200, 200, 200);};
			--Switch={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--VerticalGrip={		DefaultColor=Color3.fromRGB(40, 40, 40);};
		};
	};
	["m4a4"]={
		ToolGripModel="m4a4";
		ToolGrip={
			--Barrel={		DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Barrel";};
			--Body={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			--ChamberCover={	DefaultColor=Color3.fromRGB(90, 90, 90);};
			--ChargingHandle={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			--FrontSightPost={	DefaultColor=Color3.fromRGB(70, 70, 70);};
			--Handguard={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Handle={	DefaultColor=Color3.fromRGB(10, 10, 10);};
			--MagRelease={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Magazine={	DefaultColor=Color3.fromRGB(60, 60, 60);};
			--RearSight={	DefaultColor=Color3.fromRGB(70, 70, 70);};
			--Screws={	DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Slide={	DefaultColor=Color3.fromRGB(91, 93, 105);};
			--SlideRelease={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Stock={	DefaultColor=Color3.fromRGB(40, 40, 40);};
			
		};
	};
	["ak47"]={
		ToolGripModel="ak47";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={
			--Barral={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Barrel";};
			--Body={			DefaultColor=Color3.fromRGB(40, 40, 40);};
			--ChargingHandle={DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Charging Handle";};
			--Grip={			DefaultColor=Color3.fromRGB(52, 35, 19);	PartName="Grips";};
			--Handle={		DefaultColor=Color3.fromRGB(52, 35, 19);};
			--Magazine={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Safety={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Stock={			DefaultColor=Color3.fromRGB(52, 35, 19);};
			--StockGrip={			DefaultColor=Color3.fromRGB(60, 60, 60);};
		};
	};
	["awp"]={
		ToolGripModel="awp";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(0));
		ToolGrip={
			--Barrel={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Chamber={		DefaultColor=Color3.fromRGB(70, 70, 70);};
			--Grip={		DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Handle={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--LensCover={		DefaultColor=Color3.fromRGB(70, 70, 70);};
			--LensCover2={		DefaultColor=Color3.fromRGB(70, 70, 70);};
			--Magazine={		DefaultColor=Color3.fromRGB(70, 70, 70);};
			--Rails={		DefaultColor=Color3.fromRGB(27, 42, 53);};
			--RecoilPad={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--ScopeAdjuster={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--ScopeBody={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--ScopeGuards={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--ScopeHandle={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--ScopeLens={	DefaultColor=Color3.fromRGB(212, 244, 255);	PartName="Scope Lens"; SkipPattern = true; ToggleVisibility=true;};
			--Screws={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Slide={		DefaultColor=Color3.fromRGB(70, 70, 70);};
			--SlideHandle={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Stock={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--TopRails={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Trigger={		DefaultColor=Color3.fromRGB(140, 140, 140);};
		};
	};
	["minigun"]={
		ToolGripModel="minigun";
		ToolGripOffset=CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(0));
		ToolGrip={
			--BarrelGuard={		DefaultColor=Color3.fromRGB(27, 42, 53);	PartName="Barrel Guards";};
			--Barrels={			DefaultColor=Color3.fromRGB(120, 120, 120);	PartName="Barrels";};
			--Chassis={			DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Cover={			DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Connector={			DefaultColor=Color3.fromRGB(120, 120, 120);};
			--ElectricMotor={			DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Grip={			DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Handle={			DefaultColor=Color3.fromRGB(40, 40, 40);};
			--MagRelease={			DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Magazine={			DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Wire={			DefaultColor=Color3.fromRGB(99, 95, 98);};
			
		};
	};
	["flamethrower"]={
		ToolGripModel="flamethrower";
		ToolGripOffset=CFrame.new(1, 0, 0) * CFrame.Angles(0, math.rad(90), 0);
		ToolGrip={
			--Barral={		DefaultColor=Color3.fromRGB(150, 150, 150);	PartName="Barrel";};
			--FrontBarral={	DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Front Barrel";};
			--GasPipe={		DefaultColor=Color3.fromRGB(60, 60, 60); 	PartName="Gas Line";};
			--Handle={		DefaultColor=Color3.fromRGB(40, 40, 40); 	PartName="Body";};
			--Magazine={		DefaultColor=Color3.fromRGB(117, 44, 44); 	PartName="Gas Tank";};
			--TankHolder={	DefaultColor=Color3.fromRGB(60, 60, 60); 	PartName="Tank Anchor";};
			--Trigger={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Hinge={		DefaultColor=Color3.fromRGB(40, 40, 40);};
		};
	};
	["grenadelauncher"]={
		ToolGripModel="grenadelauncher";
		ToolGripOffset=CFrame.new(0, 0, -1) * CFrame.Angles(0, math.rad(90), 0);
		ToolGrip={
			--BackBody={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Back Body";};
			--Barrel={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--BarrelGuard={		DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Barrel Guard";};
			--FrontBody={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Front Body";};
			--GripHandle={		DefaultColor=Color3.fromRGB(60, 60, 60);PartName="Grip Handle";};
			--Grips={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Handle={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--MagCase={		DefaultColor=Color3.fromRGB(160, 160, 160);	PartName="Magazine Casing";};
			--MagChambers={		DefaultColor=Color3.fromRGB(95, 42, 43);	PartName="Magazine Chamber";};
			--Rails={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Sights={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--StockBack={		DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Stock Back";};
			--StockBody={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Stock Body";};
			--StockExtender={		DefaultColor=Color3.fromRGB(160, 160, 160);	PartName="Stock Extender";};
			--Support1={		DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Support 1";};
			--Support2={		DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Support 2";};
		};
	};
	["m9legacy"]={
		ToolGripModel="m9legacy";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0,0);
		ToolGrip={
			--Barrel={		DefaultColor=Color3.fromRGB(160, 160, 160);};
			--Furniture={		DefaultColor=Color3.fromRGB(110, 110, 110);};
			--Grip={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Hammer={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Handle={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--MagRelease={		DefaultColor=Color3.fromRGB(110, 110, 110);};
			--Magazine={		DefaultColor=Color3.fromRGB(70, 70, 70);};
			--Safety={		DefaultColor=Color3.fromRGB(86, 36, 36);};
			--Screws={		DefaultColor=Color3.fromRGB(223, 223, 222);};
			--Slide={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Trigger={		DefaultColor=Color3.fromRGB(60, 60, 60);};
		};
	};
	["revolver454"]={
		ToolGripModel="revolver454";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0,0,0);
		ToolGrip={
			--BackSight={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Back Sight";};
			--Barrel={		DefaultColor=Color3.fromRGB(160, 160, 160);};
			--Body={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--BulletChamber={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Bullet Chamber";};
			--ChamberRod={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Chamber Rod";};
			--FrontSight={		DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Front Sight";};
			--Hammer={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Handle={		DefaultColor=Color3.fromRGB(86, 66, 54);};
			--TopRails={		DefaultColor=Color3.fromRGB(40, 40, 40);	PartName="Top Rails";};
			--Trigger={		DefaultColor=Color3.fromRGB(40, 40, 40);};
		};
	};
	["mariner590"]={
		ToolGripModel="mariner590";
		ToolGrip={
			--Barrel={	DefaultColor=Color3.fromRGB(160, 160, 160);	PartName="Barrels";};
			--Body={		DefaultColor=Color3.fromRGB(160, 160, 160);};
			--Dots={		DefaultColor=Color3.fromRGB(0, 255, 0);};
			--Handle={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Lever={		DefaultColor=Color3.fromRGB(50, 50, 50);};
			--Pump={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Rails={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Safety={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--Slide={		DefaultColor=Color3.fromRGB(116, 134, 157);};
			--StockPad={		DefaultColor=Color3.fromRGB(32, 44, 56);};
			--Trigger={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--TriggerGuard={		DefaultColor=Color3.fromRGB(60, 60, 60);};
		};
	};
	["czevo3"]={
		ToolGripModel="czevo3";
		ToolGrip={
			--Barrel={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Body={			DefaultColor=Color3.fromRGB(60, 60, 60);		PartName="Body";};
			--Body2={			DefaultColor=Color3.fromRGB(100, 100, 100); 	PartName="Strap Connect";};
			--BoltCatcher={	DefaultColor=Color3.fromRGB(120, 120, 120); 	PartName="Bolt Catcher";};
			--ChamberGate={	DefaultColor=Color3.fromRGB(56, 57, 65); 		PartName="Chamber Gate";};
			--ChargingHandle={DefaultColor=Color3.fromRGB(120, 120, 120); 	PartName="Charging Handle";};
			--FrontSight={	DefaultColor=Color3.fromRGB(100, 100, 100); 	PartName="Front Sight";};
			--Handguard={		DefaultColor=Color3.fromRGB(60, 60, 60); 		PartName="Handguard";};
			--Handle={		DefaultColor=Color3.fromRGB(100, 100, 100); 	PartName="Handle";};
			--Mag={			DefaultColor=Color3.fromRGB(100, 100, 100); 	PartName="Magazine";};
			--Magwell={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Rails={			DefaultColor=Color3.fromRGB(120, 120, 120);};
			--RearSight={		DefaultColor=Color3.fromRGB(100, 100, 100);		PartName="Rear Sight";};
			--Safety={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Screws={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--SightDot={		DefaultColor=Color3.fromRGB(0, 117, 0);			PartName="Sight Dot";};
			--Stock={			DefaultColor=Color3.fromRGB(100, 100, 100);};
			--StockHinge={	DefaultColor=Color3.fromRGB(120, 120, 120);		PartName="Stock Hinge";};
			--Trigger={		DefaultColor=Color3.fromRGB(120, 120, 120);};
		};
	};
	["fnfal"]={
		ToolGripModel="fnfal";
		ToolGrip={
			--Barrel={ DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Body={ DefaultColor=Color3.fromRGB(60, 60, 60);};
			--CarryHandle={ DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Chamber={ DefaultColor=Color3.fromRGB(56, 57, 65);};
			--ChargingHandle={ DefaultColor=Color3.fromRGB(56, 57, 65);};
			--Grip={ DefaultColor=Color3.fromRGB(53, 34, 28);};
			--Handle={ DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Magazine={ DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Screws={ DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Stock={ DefaultColor=Color3.fromRGB(53, 34, 28);};
			--StockGrip={ DefaultColor=Color3.fromRGB(60, 60, 60);};
			--StockStart={ DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Switch={ DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Trigger={ DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Body={			DefaultColor=Color3.fromRGB(40, 40, 40);		};
			--CarryHandle={			DefaultColor=Color3.fromRGB(53, 34, 28); 	PartName="Carry Handle"; ToggleVisibility=true;};
			--CarryBody={			DefaultColor=Color3.fromRGB(40, 40, 40); 	PartName="Carry Handle Body"; ToggleVisibility=true;};
			--ChamberCharge={	DefaultColor=Color3.fromRGB(56, 57, 65); 	PartName="Chamber Charge";};
			--ChargingHandle={	DefaultColor=Color3.fromRGB(60, 60, 60); 		PartName="Charging Handle";};
			--FrontGrip={DefaultColor=Color3.fromRGB(53, 34, 28); 	PartName="Front Grip";};
			--FrontSight={	DefaultColor=Color3.fromRGB(60, 60, 60); 	PartName="Front Sight";};
			--Handle={		DefaultColor=Color3.fromRGB(40, 40, 40); 		};
			--Magazine={		DefaultColor=Color3.fromRGB(60, 60, 60); 	};
			--Reciever={			DefaultColor=Color3.fromRGB(60, 60, 60); 	};
			--RearSight={			DefaultColor=Color3.fromRGB(40, 40, 40); 	PartName="Rear Sight";};
			--Screws={		DefaultColor=Color3.fromRGB(60, 60, 60);};
			--ShellRelease={			DefaultColor=Color3.fromRGB(56, 57, 65);};
			--SightDot={		DefaultColor=Color3.fromRGB(0, 98, 0);		PartName="Sight Dot";};
			--Stock={		DefaultColor=Color3.fromRGB(53, 34, 28);};
			--StockGrip={		DefaultColor=Color3.fromRGB(60, 60, 60); PartName="Stock Grip";};
			--Trigger={		DefaultColor=Color3.fromRGB(60, 60, 60);			};
		};
	};
	["tacticalbow"]={
		LeftToolGripModel="tacticalbow";
		LeftToolGripOffset=CFrame.new(0, 0, 0);
		LeftToolGrip={
			--Body={		DefaultColor=Color3.fromRGB(140, 140, 140);};
			--BodyBevels={			DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Body Bevels";};
			--BodyScrews={			DefaultColor=Color3.fromRGB(200, 200, 200); 	PartName="Body Screws";};
			--Counterweight={	DefaultColor=Color3.fromRGB(40, 40, 40); };
			--Grip={	DefaultColor=Color3.fromRGB(105, 64, 40);};
			--Handle={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--LowerAnchorScrew={	DefaultColor=Color3.fromRGB(100, 100, 100); };
			--LowerFiberglass={	DefaultColor=Color3.fromRGB(200, 200, 200); };
			--LowerScrews={	DefaultColor=Color3.fromRGB(200, 200, 200); };
			--LowerSupport={	DefaultColor=Color3.fromRGB(100, 100, 100); };
			--Sight={	DefaultColor=Color3.fromRGB(140, 140, 140); };
			--SightAssist={	DefaultColor=Color3.fromRGB(255, 0, 0); };
			--UpperAnchorScrew={	DefaultColor=Color3.fromRGB(100, 100, 100); };
			--UpperFiberglass={	DefaultColor=Color3.fromRGB(200, 200, 200); };
			--UpperScrews={	DefaultColor=Color3.fromRGB(200, 200, 200); };
			--UpperSupport={	DefaultColor=Color3.fromRGB(100, 100, 100); };
		};
	};
	["desolatorheavy"]={
		ToolGripModel="desolatorheavy";
		ToolGrip={
			--Barrel={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Bipod={DefaultColor=Color3.fromRGB(100, 100, 100); ToggleVisibility=true;};
			--BipodSupport={DefaultColor=Color3.fromRGB(160, 160, 160); ToggleVisibility=true;};
			--Body={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Bolt={DefaultColor=Color3.fromRGB(140, 140, 140);};
			--FrontGrip={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--FrontSight={DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Guard={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Handle={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--HandleGrip={DefaultColor=Color3.fromRGB(140, 140, 140);};
			--MagInsert={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--MagTop={DefaultColor=Color3.fromRGB(140, 140, 140);};
			--MagWell={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Magazine={DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Muzzle={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--RearSight={DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Screws={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--Stock={DefaultColor=Color3.fromRGB(160, 160, 160);};
			--StockGrip={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--TopRail={DefaultColor=Color3.fromRGB(160, 160, 160);};
			--Trigger={DefaultColor=Color3.fromRGB(200, 200, 200);};
		};
	};
	["rec21"]={
		ToolGripModel="rec21";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={
			--Barral={		DefaultColor=Color3.fromRGB(180, 180, 180);};
			--BarralGuard={	DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Body={			DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Chamber={			DefaultColor=Color3.fromRGB(180, 180, 180);};
			--Handle={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--MagWell={		DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Magazine={		DefaultColor=Color3.fromRGB(180, 180, 180);};
			--Receiver={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--RecoilPad={		DefaultColor=Color3.fromRGB(40, 40, 40);};
			--Scope={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--ScopeAdjuster={		DefaultColor=Color3.fromRGB(120, 120, 120);};
			--ScopeGuard={		DefaultColor=Color3.fromRGB(90, 90, 90);};
			--ScopeLens={	DefaultColor=Color3.fromRGB(212, 244, 255); SkipPattern = true; ToggleVisibility=true;};
			--SlideHandle={		DefaultColor=Color3.fromRGB(180, 180, 180);};
			--Stock={		DefaultColor=Color3.fromRGB(140, 140, 140);};
			--Trigger={		DefaultColor=Color3.fromRGB(90, 90, 90);};
		};
		--ToolGrip={
		--	Barrel={		DefaultColor=Color3.fromRGB(100, 100, 100);};
		--	BarrelGuard={	DefaultColor=Color3.fromRGB(140, 140, 140);	PartName="Body Screws";};
		--	Body={			DefaultColor=Color3.fromRGB(140, 140, 140);};
		--	Glass={	DefaultColor=Color3.fromRGB(212, 244, 255);	PartName="Scope Lens"; SkipPattern = true};
		--	Handle={		DefaultColor=Color3.fromRGB(140, 140, 140);};
		--	MagWell={		DefaultColor=Color3.fromRGB(100, 100, 100);};
		--	Magazine={		DefaultColor=Color3.fromRGB(60, 60, 60);};
		--	ScopeAbjuster={	DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Scope Knobs";};
		--	ScopeBody={	DefaultColor=Color3.fromRGB(100, 100, 100);	PartName="Scope";};
		--	ScopeHolders={		DefaultColor=Color3.fromRGB(60, 60, 60);	PartName="Scope Attach";};
		--	Slide={	DefaultColor=Color3.fromRGB(100, 100, 100);};
		--	Switch={			DefaultColor=Color3.fromRGB(60, 60, 60);};
		--	Trigger={		DefaultColor=Color3.fromRGB(90, 90, 90);};
		--};
	};
	["at4"]={
		ToolGripModel="at4";
		ToolGrip={
			--BackBody={DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Body={DefaultColor=Color3.fromRGB(127, 142, 100);};
			--BodyGrips={DefaultColor=Color3.fromRGB(40, 40, 40);};
			--FrontBody={DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Grip={DefaultColor=Color3.fromRGB(90, 90, 90);};
			--GripScrew={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Handle={DefaultColor=Color3.fromRGB(90, 90, 90);};
			--IronSight={DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Screws={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Trigger={DefaultColor=Color3.fromRGB(99, 95, 98);};
		};
	};
	["sr308"]={
		ToolGripModel="sr308";
		ToolGrip={
			--Barrel={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Body={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--ChargingHandle={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--ChargingHandle2={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Flashlight={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--FlashlightNeon={DefaultColor=Color3.fromRGB(168, 165, 146);};
			--Grip={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--HandGuard={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--Handle={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--HandleGrip={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--HoloDot={DefaultColor=Color3.fromRGB(255, 84, 84);};
			--HoloGlass={DefaultColor=Color3.fromRGB(82, 124, 174);};
			--HoloSight={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--MagWell={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Magazine={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Rails={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--RailsScrew={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Receiver={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--Screws={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Slide={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Stock={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Stripe={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Top={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Trigger={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Barrel={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Base={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--Body={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--BulletEject={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--ChargingHandle={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Flashlight={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--FlashlightNeon={DefaultColor=Color3.fromRGB(168, 165, 146);};
			--FrontGrip={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Handle={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--HoloDot={DefaultColor=Color3.fromRGB(199, 64, 64);};
			--HoloGlass={DefaultColor=Color3.fromRGB(82, 124, 174); SkipPattern = true; ToggleVisibility=true;};
			--HoloSight={DefaultColor=Color3.fromRGB(100, 100, 100); ToggleVisibility=true;};
			--MagWell={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Magazine={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Rail={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Screws={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--StockBody={DefaultColor=Color3.fromRGB(138, 165, 116);};
			--StockGrip={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Stripe={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Top={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Trigger={DefaultColor=Color3.fromRGB(100, 100, 100);};
		};
	};
	["vectorx"]={
		ToolGripModel="vectorx";
		ToolGrip={
			--Body={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Magazine={DefaultColor=Color3.fromRGB(120, 120, 120);};
			--EjectPort={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Trigger={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--StockGrip={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--ChargingHandle={DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Safety={DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Stock={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--TriggerGuard={DefaultColor=Color3.fromRGB(60, 60, 60);};
			--Stockpipe={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--HoloDot={DefaultColor=Color3.fromRGB(199, 64, 64);};
			--Handle={DefaultColor=Color3.fromRGB(120, 120, 120);};
			--MagButton={DefaultColor=Color3.fromRGB(27, 42, 53);};
			--HoloGlass={DefaultColor=Color3.fromRGB(51, 88, 130); SkipPattern = true; ToggleVisibility=true;};
			--BoltLock={DefaultColor=Color3.fromRGB(27, 42, 53);};
			--BottomRails={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Screws={DefaultColor=Color3.fromRGB(248, 248, 248);};
			--Suppressor={DefaultColor=Color3.fromRGB(120, 120, 120);};
			--Chassis={DefaultColor=Color3.fromRGB(213, 115, 61);};
			--TopRails={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--HoloBody={DefaultColor=Color3.fromRGB(60, 60, 60); ToggleVisibility=true;};
		};
	};
	["rusty48"]={
		ToolGripModel="rusty48";
		ToolGripOffset=CFrame.new(0, 0, 1.7);
		ToolGrip={
			--Barrel={DefaultColor=Color3.fromRGB(190, 104, 98);};
			--BarrelGuard={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--ChargingBolt={DefaultColor=Color3.fromRGB(190, 104, 98);};
			--DrumBody={DefaultColor=Color3.fromRGB(27, 42, 53);};
			--DrumFrame={DefaultColor=Color3.fromRGB(99, 95, 98);};
			--DrumGuard={DefaultColor=Color3.fromRGB(190, 104, 98);};
			--DrumHinge={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--DuctTape={DefaultColor=Color3.fromRGB(67, 67, 80); ToggleVisibility=true;};
			--FrontGrip={DefaultColor=Color3.fromRGB(150, 104, 77);};
			--FrontGripGuard={DefaultColor=Color3.fromRGB(80, 80, 80);};
			--Handle={DefaultColor=Color3.fromRGB(150, 104, 77);};
			--HeatPipe={DefaultColor=Color3.fromRGB(190, 104, 98);};
			--Receiver={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--RecoilBolt={DefaultColor=Color3.fromRGB(202, 203, 209); ToggleVisibility=true;};
			--RecoilSpring={DefaultColor=Color3.fromRGB(190, 104, 98); ToggleVisibility=true;};
			--Screws={DefaultColor=Color3.fromRGB(120, 120, 120);};
			--ShellEntrance={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Sights={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--StockGuard={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Trigger={DefaultColor=Color3.fromRGB(120, 120, 120);};
			--TriggerGuard={DefaultColor=Color3.fromRGB(80, 80, 80);};
		};
	};
	["arelshiftcross"]={
		ToolGripModel="arelshiftcross";
		ToolGripOffset=CFrame.new(0, 0, 0);
		ToolGrip={
			--["Acog Base"]={DefaultColor=Color3.fromRGB(100, 100, 100); ToggleVisibility=true;};
			--["Acog Body"]={DefaultColor=Color3.fromRGB(100, 100, 100); ToggleVisibility=true;};
			--["Acog Detail1"]={DefaultColor=Color3.fromRGB(200, 200, 200); ToggleVisibility=true;};
			--["Acog Detail2"]={DefaultColor=Color3.fromRGB(200, 200, 200); ToggleVisibility=true;};
			--["Acog Knobs"]={DefaultColor=Color3.fromRGB(100, 100, 100); ToggleVisibility=true;};
			--["Acog Screws"]={DefaultColor=Color3.fromRGB(200, 200, 200); ToggleVisibility=true;};
			--["AcogLens"]={DefaultColor=Color3.fromRGB(212, 244, 255); ToggleVisibility=true;};
			
			--["Arm Screws"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Body"]={DefaultColor=Color3.fromRGB(150, 150, 150);};
			--["Crank Box"]={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--["Crank Detail"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Crank Handle Base"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Crank Handle Left"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Crank Handle Right"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Furniture"]={DefaultColor=Color3.fromRGB(231, 231, 236);};
			--["Furniture Box"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Grip"]={DefaultColor=Color3.fromRGB(108, 88, 75);};
			--["Hand Gaurd"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Handle"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Head Rest"]={DefaultColor=Color3.fromRGB(108, 88, 75);};
			--["Left Arm"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Left Arm Base"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Left Cam"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Left Cam Box"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Mag Release"]={DefaultColor=Color3.fromRGB(231, 231, 236);};
			--["Mag Well"]={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--["Magazine Body"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Magazine plastic"]={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--["Rails"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Right Arm"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Right Arm Base"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Right Cam"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Right Cam Box"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Riser"]={DefaultColor=Color3.fromRGB(100, 100, 100);};
			--["Riser screws"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Scope mount"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Stock End"]={DefaultColor=Color3.fromRGB(108, 88, 75);};
			--["Stock Pipes"]={DefaultColor=Color3.fromRGB(200, 200, 200);};
			--["Stock part"]={DefaultColor=Color3.fromRGB(163, 162, 165);};
			--["Trigger"]={DefaultColor=Color3.fromRGB(231, 231, 236);};
			--["Wrench"]={DefaultColor=Color3.fromRGB(248, 248, 248);};
		};
	};
	
	
	--== Melee
	["survivalknife"]={
		ToolGripModel="survivalknife";
		ToolGripOffset=CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90));
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(108, 88, 75);};
			--Blade={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Edge={		DefaultColor=Color3.fromRGB(223, 223, 222);};
		};
	};
	["machete"]={
		ToolGripModel="machete";
		ToolGripOffset=CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(108, 88, 75);};
			--Blade={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Edge={		DefaultColor=Color3.fromRGB(223, 223, 222);};
		};
	};
	["spikedbat"]={
		ToolGripModel="spikedbat";
		ToolGripOffset=CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Body={		DefaultColor=Color3.fromRGB(159, 114, 76);};
			--Spikes={		DefaultColor=Color3.fromRGB(135, 134, 136); ToggleVisibility=true;};
			--UpperRim={		DefaultColor=Color3.fromRGB(59, 78, 98);};
			--LowerRim={		DefaultColor=Color3.fromRGB(59, 78, 98);};
		};
	};
	["naughtycane"]={
		ToolGripModel="naughtycane";
		ToolGripOffset=CFrame.new(0, -0.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(237, 234, 234);};
			--Stripe={		DefaultColor=Color3.fromRGB(193, 110, 110);};
			--Bow={		DefaultColor=Color3.fromRGB(193, 110, 110);};
		};
	};
	["crowbar"]={
		ToolGripModel="crowbar";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(213, 41, 8);};
			--Top={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Bot={		DefaultColor=Color3.fromRGB(163, 162, 165);};
		};
	};
	["sledgehammer"]={
		ToolGripModel="sledgehammer";
		ToolGripOffset=CFrame.new(0, -1.3, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Head={		DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Mount={		DefaultColor=Color3.fromRGB(204, 142, 105);};
			--UpperHandle={DefaultColor=Color3.fromRGB(188, 155, 93);};
		};
	};
	["pickaxe"]={
		ToolGripModel="pickaxe";
		ToolGripOffset=CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--BackPoint={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--CenterPiece={	DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Handle={		DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Pointed={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--UpperHandle={	DefaultColor=Color3.fromRGB(188, 155, 93);};
		};
	};
	["broomspear"]={
		ToolGripModel="broomspear";
		ToolGripOffset=CFrame.new();
	};
	["jacksscythe"]={
		ToolGripModel="jacksscythe";
		ToolGripOffset=CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Blade={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Guard={	DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Handle={		DefaultColor=Color3.fromRGB(86, 36, 36);};
			--Top={		DefaultColor=Color3.fromRGB(126, 104, 63);};
		};
	};
	["chainsaw"]={
		ToolGripModel="chainsaw";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--BladeFrame={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--Body={	DefaultColor=Color3.fromRGB(100, 100, 100);};
			--Dampener={		DefaultColor=Color3.fromRGB(150, 150, 150);};
			--FlashlightBody={		DefaultColor=Color3.fromRGB(202, 203, 209);};
			--Handle={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--HandleGuard={		DefaultColor=Color3.fromRGB(100, 100, 100);};
			--InfoPanel={		DefaultColor=Color3.fromRGB(150, 150, 150);};
			--Power={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--Rim={		DefaultColor=Color3.fromRGB(239, 184, 56);};
			--Screws={		DefaultColor=Color3.fromRGB(248, 248, 248);};
			--Shield={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--TopHandle={		DefaultColor=Color3.fromRGB(91, 93, 105);};
		};
	};
	["shovel"]={
		ToolGripModel="shovel";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Blade={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Handle={	DefaultColor=Color3.fromRGB(204, 143, 93);};
			--Hinge={		DefaultColor=Color3.fromRGB(159, 161, 172);};
			--Joint={		DefaultColor=Color3.fromRGB(39, 70, 45);};
			--MetalFrame={		DefaultColor=Color3.fromRGB(39, 70, 45);};
			--Screws={		DefaultColor=Color3.fromRGB(159, 161, 172);};
		};
	};
	["inquisitorssword"]={
		ToolGripModel="inquisitorssword";
		ToolGripOffset=CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Beta={	DefaultColor=Color3.fromRGB(226, 155, 64); ToggleVisibility=true;};
			--Blade1={	DefaultColor=Color3.fromRGB(99, 95, 98);};
			--Blade2={	DefaultColor=Color3.fromRGB(99, 95, 98); ToggleVisibility=true;};
			--Blade3={	DefaultColor=Color3.fromRGB(99, 95, 98); ToggleVisibility=true;};
			--Blade4={	DefaultColor=Color3.fromRGB(99, 95, 98); ToggleVisibility=true;};
			--Blade5={	DefaultColor=Color3.fromRGB(99, 95, 98); ToggleVisibility=true;};
			--Grip={	DefaultColor=Color3.fromRGB(86, 66, 54);};
			--Handle={	DefaultColor=Color3.fromRGB(27, 42, 53);};
			--InnerBlade={	DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Quillon={	DefaultColor=Color3.fromRGB(82, 124, 174);};
		};
	};
	["fireaxe"]={
		ToolGripModel="fireaxe";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--AxeBlade={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--AxeHead={		DefaultColor=Color3.fromRGB(190, 104, 98);};
			--Body={		DefaultColor=Color3.fromRGB(226, 155, 64);};
			--Handle={		DefaultColor=Color3.fromRGB(27, 42, 53);};
			--HeadCap={		DefaultColor=Color3.fromRGB(27, 42, 53);};
			--Rope={		DefaultColor=Color3.fromRGB(199, 172, 120);};
			--RopeKnots={		DefaultColor=Color3.fromRGB(199, 172, 120);};
		};
	};
	["boomerang"]={
		ToolGripModel="boomerang";
		ToolGripOffset=CFrame.new();
	};
	
	
	--== Tools
	["wateringcan"]={
		ToolGripModel="wateringcan";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={	DefaultColor=Color3.fromRGB(39, 70, 45);};
			--Output={	DefaultColor=Color3.fromRGB(39, 70, 45);};
		};
	};
	["lantern"]={
		ToolGripModel="lantern";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Base={			DefaultColor=Color3.fromRGB(150, 85, 85);};
			--Grips={			DefaultColor=Color3.fromRGB(108, 88, 75);};
			--Lamp={			DefaultColor=Color3.fromRGB(206, 144, 99);};
			--Shield={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Top={			DefaultColor=Color3.fromRGB(150, 85, 85);};
		};
	};
	["spotlight"]={
		ToolGripModel="spotlight";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Bars={		DefaultColor=Color3.fromRGB(159, 161, 172);};
			--Body={			DefaultColor=Color3.fromRGB(87, 96, 112);};
			--Handle={			DefaultColor=Color3.fromRGB(159, 161, 172);};
		};
	};
	["musicbox"]={
		ToolGripModel="musicbox";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Handle={		DefaultColor=Color3.fromRGB(161, 106, 58);};
			--BrassPlate={	DefaultColor=Color3.fromRGB(245, 205, 48);};
			--Glass={			DefaultColor=Color3.fromRGB(180, 210, 228);};
			--Hinges={		DefaultColor=Color3.fromRGB(108, 88, 75);};
			--Mech={			DefaultColor=Color3.fromRGB(108, 88, 75);};
			--Top={			DefaultColor=Color3.fromRGB(161, 106, 58);};
		};
	};
	["binoculars"]={
		ToolGripModel="binoculars";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--Bridge={		DefaultColor=Color3.fromRGB(80, 109, 84);};
			--Glass={			DefaultColor=Color3.fromRGB(149, 173, 158);};
			--Grips={			DefaultColor=Color3.fromRGB(44, 63, 43);};
			--Handle={		DefaultColor=Color3.fromRGB(39, 70, 45);};
			--Hinge={			DefaultColor=Color3.fromRGB(86, 66, 54);};
			--Rims={			DefaultColor=Color3.fromRGB(39, 70, 45);};
		};
	};
	["keytar"]={
		ToolGripModel="keytar";
		ToolGripOffset=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0);
		ToolGrip={
			--AttachPlate={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Blade={		DefaultColor=Color3.fromRGB(248, 248, 248);};
			--BottomKnobs={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--FrontButtons={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--Handle={		DefaultColor=Color3.fromRGB(147, 153, 188);};
			--Scews={		DefaultColor=Color3.fromRGB(163, 162, 165);};
			--Speakers={		DefaultColor=Color3.fromRGB(27, 42, 53);};
			--TopKnobs={		DefaultColor=Color3.fromRGB(91, 93, 105);};
			--TouchSens={		DefaultColor=Color3.fromRGB(27, 42, 53);};
		};
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
	PolishLimitReached = 8
}, {__index={
	"Please try again after 1 second.";
	"You are too far from workbench.";
	"Invalid Item.";
	"The workbench is full.";
	"Inventory is full.";
	"Cannot polish modded item.";
	"Insufficient resources.";
	"Can not polish anymore.";
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