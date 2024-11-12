local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local modItemsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = Debugger:Require(game.ReplicatedStorage.Library.Configurations);
local modItemModsLibrary = modModEngineService:GetBaseModule("ItemModsLibrary");

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);
--
local colorBoolText = modRichFormatter.ColorBoolText;
local colorStringText = modRichFormatter.ColorStringText;
local colorNumberText = modRichFormatter.ColorNumberText;

local BlueprintLibrary = {};
BlueprintLibrary.Identifiers = {};
BlueprintLibrary.CheckBlueprintFulfilment = nil; -- Server Only;

local library = {};

function BlueprintLibrary.Get(id)
	return library[id];
end

function BlueprintLibrary:FindByName(name)
	for id, data in pairs(library) do
		if data.Name == name then
			return data;
		end
	end
	return;
end

function BlueprintLibrary:Loop(func)
	for key, _ in pairs(library) do
		func(key, library[key]);
	end
end

local countCategory = {};
function BlueprintLibrary:CountCategory(name)
	if countCategory[name] then return countCategory[name] end;
	
	local c=0;
	for id, data in pairs(library) do
		if data.Category == name then
			c = c +1;
		end
	end
	countCategory[name] = c;
	
	return countCategory[name];
end

function BlueprintLibrary:SortCategories(list)
	local sorted = {};
	for id, _ in pairs(list) do
		local bpLib = BlueprintLibrary.Get(id);
		local category = bpLib.Category or "Unknown";
		if sorted[category] == nil then sorted[category] = {} end;
		table.insert(sorted[category], id); 
	end
	return sorted;
end

local Lib = modItemsLibrary.Library;
local function new(b, d)
	b.__index=b;
	modItemsLibrary:Add(setmetatable(d, b));
end;

local blueprintBase = {
	Type = modItemsLibrary.Types.Blueprint;
	Tradable = modItemsLibrary.Tradable.Tradable;
	Stackable = 5;
};

function BlueprintLibrary.New(data)
	if modConfigurations["DisableScript:"..script.Name] == true then return end;
	
	if library[data.Id] ~= nil then error("BlueprintLibrary>>  Blueprint ID ("..data.Id..") already exist for ("..data.Name..").") end;
	library[data.Id] = data;
	library[data.Id].CanUnlock = true;
	
	if data.Category == "Weapons" or data.Category == "Clothing" or data.Category == "Summons" then
		library[data.Id].CanUnlock = false;
	end
	if data.CanUnlock == false then
		library[data.Id].CanUnlock = false;
	end
	
	local productLib = modItemsLibrary:Find(data.Product);
	while productLib == nil do
		task.wait(1);
		productLib = modItemsLibrary:Find(data.Product);
		if productLib == nil then
			Debugger:Warn("Waiting for product (",data.Product,") from bp:", data.Id);
			Debugger:Warn("find ",modItemsLibrary.Library:GetKeys())
		end
	end
	if productLib == nil then
		error("BlueprintLibrary>>  Blueprint ID ("..data.Id..") has a unknown product ("..data.Product..").");
	end
	BlueprintLibrary.Identifiers[data.Name] = data.Id;
	local desc = "Used to build "..productLib.Name..(data.Type == modItemsLibrary.Types.Mod and " Mod" or "").." from the workbench.";
	
	local requireDesc = "";
	for a=1, #data.Requirements do
		local r = data.Requirements[a];
		local itemLib = modItemsLibrary:Find(r.ItemId);
		if r.Name == "Money" then
			requireDesc = requireDesc.."\n    - ".. colorNumberText("$"..r.Amount);
		else
			requireDesc = requireDesc.."\n    - ".. colorStringText(r.Amount.." ".. (r.Name or itemLib.Name));
		end
	end
	
	new(blueprintBase, {
		Id=data.Id; 
		Name=data.Name; 
		Icon=productLib.Icon; 
		Description=desc;
		Sources=data.Sources;
		Tags=data.Tags;
		RequireDesc = requireDesc;
		TradingTax=data.TradingTax;
	});
	--modItem.new(data.Id, data.Name, modItem.Types.Blueprint, productLib.Icon, 5, desc, "Tradable", data.Tier);
end

local hourSec = 3600;
local daySec = hourSec*24;
--== MARK: Tools
BlueprintLibrary.New{
	Id="medkitbp";
	Name="Medkit Blueprint";
	Product="medkit";
	Amount=3;
	Duration=5;
	Requirements={
		{Type="Item"; ItemId="cloth"; Amount=15;};
	};
	Sources={"Obtained from <b>Dr. Deniski in Mission: Bandage Up</b>";};
	Category="Medical Supplies";
};

BlueprintLibrary.New{
	Id="largemedkitbp";
	Name="Large Medkit Blueprint";
	Product="largemedkit";
	Amount=2;
	Duration=5;
	Requirements={
		{Type="Item"; ItemId="cloth"; Amount=30;};
		{Type="Item"; ItemId="adhesive"; Amount=5;};
	};
	Category="Medical Supplies";
};

BlueprintLibrary.New{
	Id="stickygrenadebp";
	Name="Sticky Grenade Blueprint";
	Product="stickygrenade";
	Amount=1;
	Duration=5;
	Requirements={
		{Type="Item"; ItemId="mk2grenade"; Amount=1;};
		{Type="Item"; ItemId="adhesive"; Amount=5;};
	};
	Category="Tools";
};

--== MARK: Mods
BlueprintLibrary.New{
	Id="pistoldamagebp";
	Name="Pistol Damage Mod Blueprint";
	Product="pistoldamagemod";
	Tier=1;
	Type="Mod";
	Duration=10;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=60;};
		{Type="Item"; ItemId="metal"; Amount=10;};
	};
	Sources={"Obtained from <b>Mason in Mission: Time to Upgrade</b>";};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="pistolfireratebp";
	Name="Pistol Fire Rate Mod Blueprint";
	Product="pistolfireratemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=140;};
		{Type="Item"; ItemId="metal"; Amount=25;};
	};
	Sources={"Obtained from <b>Mason in Mission: Time to Upgrade</b>";};
	Category="Fire Rate Mods";
};

BlueprintLibrary.New{
	Id="pistolreloadspeedbp";
	Name="Pistol Reload Speed Mod Blueprint";
	Product="pistolreloadspeedmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=150;};
		{Type="Item"; ItemId="metal"; Amount=26;};
	};
	Category="Reload Speed Mods";
};

BlueprintLibrary.New{
	Id="pistolammocapbp";
	Name="Pistol Ammo Capacity Mod Blueprint";
	Product="pistolammocapmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=200;};
		{Type="Item"; ItemId="metal"; Amount=30;};
	};
	Category="Ammo Capacity Mods";
};

--============================
BlueprintLibrary.New{
	Id="subdamagebp";
	Name="Submachine Gun Damage Mod Blueprint";
	Product="subdamagemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=150;};
		{Type="Item"; ItemId="metal"; Amount=24;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="subfireratebp";
	Name="Submachine Gun Fire Rate Mod Blueprint";
	Product="subfireratemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=300;};
		{Type="Item"; ItemId="metal"; Amount=32;};
	};
	Category="Fire Rate Mods";
};

BlueprintLibrary.New{
	Id="subreloadspeedbp";
	Name="Submachine Gun Reload Speed Mod Blueprint";
	Product="subreloadspeedmod";
	Tier=1;
	Type="Mod";
	Duration=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=150;};
		{Type="Item"; ItemId="metal"; Amount=18;};
	};
	Category="Reload Speed Mods";
};

BlueprintLibrary.New{
	Id="subammocapbp";
	Name="Submachine Gun Ammo Capacity Mod Blueprint";
	Product="subammocapmod";
	Tier=1;
	Type="Mod";
	Duration=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=200;};
		{Type="Item"; ItemId="metal"; Amount=22;};
	};
	Category="Ammo Capacity Mods";
};

--============================
BlueprintLibrary.New{
	Id="shotgundamagebp";
	Name="Shotgun Damage Mod Blueprint";
	Product="shotgundamagemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=300;};
		{Type="Item"; ItemId="metal"; Amount=36;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="shotgunfireratebp";
	Name="Shotgun Fire Rate Mod Blueprint";
	Product="shotgunfireratemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=100;};
		{Type="Item"; ItemId="metal"; Amount=20;};
	};
	Category="Fire Rate Mods";
};

BlueprintLibrary.New{
	Id="shotgunreloadspeedbp";
	Name="Shotgun Reload Speed Mod Blueprint";
	Product="shotgunreloadspeedmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=150;};
		{Type="Item"; ItemId="metal"; Amount=18;};
	};
	Category="Reload Speed Mods";
};

BlueprintLibrary.New{
	Id="shotgunammocapbp";
	Name="Shotgun Ammo Capacity Mod Blueprint";
	Product="shotgunammocapmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=200;};
		{Type="Item"; ItemId="metal"; Amount=22;};
	};
	Category="Ammo Capacity Mods";
};

--============================
BlueprintLibrary.New{
	Id="rifledamagebp";
	Name="Rifle Damage Mod Blueprint";
	Product="rifledamagemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=55;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="riflefireratebp";
	Name="Rifle Fire Rate Mod Blueprint";
	Product="riflefireratemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=300;};
		{Type="Item"; ItemId="metal"; Amount=60;};
	};
	Category="Fire Rate Mods";
};

BlueprintLibrary.New{
	Id="riflereloadspeedbp";
	Name="Rifle Reload Speed Mod Blueprint";
	Product="riflereloadspeedmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=150;};
		{Type="Item"; ItemId="metal"; Amount=30;};
	};
	Category="Reload Speed Mods";
};

BlueprintLibrary.New{
	Id="rifleammocapbp";
	Name="Rifle Ammo Capacity Mod Blueprint";
	Product="rifleammocapmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=200;};
		{Type="Item"; ItemId="metal"; Amount=25;};
	};
	Category="Ammo Capacity Mods";
};

--============================
BlueprintLibrary.New{
	Id="sniperdamagebp";
	Name="Sniper Damage Mod Blueprint";
	Product="sniperdamagemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=80;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="sniperfireratebp";
	Name="Sniper Fire Rate Mod Blueprint";
	Product="sniperfireratemod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=300;};
		{Type="Item"; ItemId="metal"; Amount=100;};
	};
	Category="Fire Rate Mods";
};

BlueprintLibrary.New{
	Id="sniperammocapbp";
	Name="Sniper Ammo Capacity Mod Blueprint";
	Product="sniperammocapmod";
	Tier=1;
	Type="Mod";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=200;};
		{Type="Item"; ItemId="metal"; Amount=100;};
	};
	Category="Ammo Capacity Mods";
};

--============================
BlueprintLibrary.New{
	Id="pyrodamagebp";
	Name="Pyrotechnic Damage Mod Blueprint";
	Product="pyrodamagemod";
	Tier=1;
	Type="Mod";
	Duration=300;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=1000;};
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="glass"; Amount=60;};
		{Type="Item"; ItemId="igniter"; Amount=1;};
		{Type="Item"; ItemId="gastank"; Amount=1;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="pyroammocapbp";
	Name="Pyrotechnic Ammo Capacity Mod Blueprint";
	Product="pyroammocapmod";
	Tier=1;
	Type="Mod";
	Duration=300;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=3000;};
		{Type="Item"; ItemId="metal"; Amount=160;};
		{Type="Item"; ItemId="jerrycan"; Amount=1;};
	};
	Category="Ammo Capacity Mods";
};

BlueprintLibrary.New{
	Id="explosivedamagebp";
	Name="Explosive Damage Mod Blueprint";
	Product="explosivedamagemod";
	Tier=1;
	Type="Mod";
	Duration=300;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=2000;};
		{Type="Item"; ItemId="metal"; Amount=60;};
		{Type="Item"; ItemId="jerrycan"; Amount=1;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="explosiveammocapbp";
	Name="Explosive Ammo Capacity Mod Blueprint";
	Product="explosiveammocapmod";
	Tier=1;
	Type="Mod";
	Duration=300;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=3500;};
		{Type="Item"; ItemId="metal"; Amount=200;};
		{Type="Item"; ItemId="glass"; Amount=20;};
	};
	Category="Ammo Capacity Mods";
};

BlueprintLibrary.New{
	Id="bowdamagebp";
	Name="Bow Damage Mod Blueprint";
	Product="bowdamagemod";
	Tier=1;
	Type="Mod";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=5000;};
		{Type="Item"; ItemId="metal"; Amount=20;};
		{Type="Item"; ItemId="tacticalbowparts"; Amount=2;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="bowammocapbp";
	Name="Bow Ammo Capacity Mod Blueprint";
	Product="bowammocapmod";
	Tier=1;
	Type="Mod";
	Duration=300;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=8500;};
		{Type="Item"; ItemId="metal"; Amount=25;};
		{Type="Item"; ItemId="tacticalbowparts"; Amount=1;};
	};
	Category="Ammo Capacity Mods";
};

--== MARK: Edged Melee Mods
BlueprintLibrary.New{
	Id="edgeddamagebp";
	Name="Edged Melee Damage Mod Blueprint";
	Product="edgeddamagemod";
	Tier=1;
	Type="Mod";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=15000;};
		{Type="Item"; ItemId="metal"; Amount=35;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="bluntdamagebp";
	Name="Blunt Melee Damage Mod Blueprint";
	Product="bluntdamagemod";
	Tier=1;
	Type="Mod";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=15000;};
		{Type="Item"; ItemId="metal"; Amount=40;};
	};
	Category="Damage Mods";
};

BlueprintLibrary.New{
	Id="pointdamagebp";
	Name="Pointed Melee Damage Mod Blueprint";
	Product="pointdamagemod";
	Tier=1;
	Type="Mod";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=15000;};
		{Type="Item"; ItemId="metal"; Amount=20;};
		{Type="Item"; ItemId="glass"; Amount=20;};
	};
	Category="Damage Mods";
};

--== MARK: Special mod

BlueprintLibrary.New{
	Id="incendiarybp";
	Name="Incendiary Rounds Mod Blueprint";
	Product="incendiarymod";
	Type="Mod";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Level"; Amount=10;};
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="igniter"; Amount=1;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
		{Type="Item"; ItemId="gastank"; Amount=1;};
	};
	Category="Elemental Mods";
};

BlueprintLibrary.New{
	Id="electricbp";
	Name="Electric Charge Mod Blueprint";
	Product="electricmod";
	Type="Mod";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Level"; Amount=10;};
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="wires"; Amount=1;};
	};
	Category="Elemental Mods";
};

BlueprintLibrary.New{
	Id="frostbp";
	Name="Frostbite Mod Blueprint";
	Product="frostmod";
	Type="Mod";
	Duration=300;
	SellPrice=2000;
	Requirements={
		{Type="Stat"; Name="Level"; Amount=20;};
		{Type="Stat"; Name="Money"; Amount=8000;};
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="radiator"; Amount=1;};
		{Type="Item"; ItemId="gastank"; Amount=1;};
	};
	Category="Elemental Mods";
};	

BlueprintLibrary.New{
	Id="toxicbp";
	Name="Toxic Barrage Mod Blueprint";
	Product="toxicmod";
	Type="Mod";
	Duration=300;
	SellPrice=2000;
	Requirements={
		{Type="Stat"; Name="Level"; Amount=20;};
		{Type="Stat"; Name="Money"; Amount=6500;};
		{Type="Item"; ItemId="metal"; Amount=25;};
		{Type="Item"; ItemId="toxiccontainer"; Amount=1;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="wires"; Amount=1;};
	};
	Category="Elemental Mods";
};	



--== MARK: Weapons

BlueprintLibrary.New{
	Id="cz75bp";
	Name="CZ75-Auto Blueprint";
	Product="cz75";
	Duration=120;
	SellPrice=80;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=60;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="xm1014bp";
	Name="XM1014 Blueprint";
	Product="xm1014";
	Duration=120;
	SellPrice=160;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=100;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="sawedoffbp";
	Name="Sawed-Off Blueprint";
	Product="sawedoff";
	Duration=120;
	SellPrice=140;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=600;};
		{Type="Item"; ItemId="metal"; Amount=110;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="mp5bp";
	Name="MP5 Blueprint";
	Product="mp5";
	Duration=180;
	SellPrice=400;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=160;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="mp7bp";
	Name="MP7 Blueprint";
	Product="mp7";
	Duration=180;
	SellPrice=180;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=170;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="m4a4bp";
	Name="M4A4 Blueprint";
	Product="m4a4";
	Duration=300;
	SellPrice=220;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=260;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="ak47bp";
	Name="AK-47 Blueprint";
	Product="ak47";
	Duration=300;
	SellPrice=2000;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=250;};
		{Type="Item"; ItemId="wood"; Amount=30;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="tec9bp";
	Name="Tec-9 Blueprint";
	Product="tec9";
	Duration=120;
	SellPrice=100;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=400;};
		{Type="Item"; ItemId="metal"; Amount=80;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="awpbp";
	Name="AWP Blueprint";
	Product="awp";
	Duration=300;
	SellPrice=300;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=300;};
		{Type="Item"; ItemId="glass"; Amount=50;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="minigunbp";
	Name="Minigun Blueprint";
	Product="minigun";
	Duration=300;
	SellPrice=400;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=1300;};
		{Type="Item"; ItemId="metal"; Amount=150;};
		{Type="Item"; ItemId="metalpipes"; Amount=2;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="motor"; Amount=1;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="flamethrowerbp";
	Name="Flamethrower Blueprint";
	Product="flamethrower";
	Duration=300;
	SellPrice=500;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=2000;};
		{Type="Item"; ItemId="metal"; Amount=70;};
		{Type="Item"; ItemId="glass"; Amount=30;};
		{Type="Item"; ItemId="gastank"; Amount=1;};
		{Type="Item"; ItemId="metalpipes"; Amount=2;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="grenadelauncherbp";
	Name="Grenade Launcher Blueprint";
	Product="grenadelauncher";
	Duration=600;
	SellPrice=600;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=3600;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=70;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="motor"; Amount=1;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="dualp250bp";
	Name="Dual P250 Blueprint";
	Product="dualp250";
	Duration=1800;
	SellPrice=700;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=12000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=40;};
		{Type="Item"; ItemId="metal"; Amount=230;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="mariner590bp";
	Name="Mariner 590 Blueprint";
	Product="mariner590";
	Duration=1800;
	SellPrice=2880;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=22000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=60;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="revolver454bp";
	Name="Revolver 454 Blueprint";
	Product="revolver454";
	Duration=hourSec;
	SellPrice=900;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=33000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=80;};
		{Type="Item"; ItemId="metal"; Amount=60;};
		{Type="Item"; ItemId="metalpipes"; Amount=2;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="czevo3bp";
	Name="CZ Scorpion Evo 3 Blueprint";
	Product="czevo3";
	Duration=hourSec;
	SellPrice=4000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=27000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=20;};
		{Type="Item"; ItemId="metal"; Amount=120;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="fnfalbp";
	Name="FN FAL Blueprint";
	Product="fnfal";
	Duration=hourSec;
	SellPrice=600;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=33000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=140;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="wood"; Amount=20;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="m9legacybp";
	Name="M9 Legacy Blueprint";
	Product="m9legacy";
	Duration=daySec;
	SellPrice=16000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=20000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Stat"; Name="Level"; Amount=60;};
		{Type="Item"; ItemId="metal"; Amount=80;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="tacticalbowbp";
	Name="Tactical Bow Blueprint";
	Product="tacticalbow";
	Duration=daySec;
	SellPrice=32000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=55000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Stat"; Name="Level"; Amount=100;};
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="wood"; Amount=10;};
		{Type="Item"; ItemId="tacticalbowparts"; Amount=6;};
	};
	Category="Weapons";
	Sources={"Obtainable from Mission: <b>Vindictive Treasure 3</b>"; "Obtainable from <b>Bandit's Market</b> Shop"};
};

BlueprintLibrary.New{
	Id="desolatorheavybp";
	Name="Desolator Heavy Blueprint";
	Product="desolatorheavy";
	Duration=hourSec;
	SellPrice=7200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=35000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=100;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="motor"; Amount=1;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="rec21bp";
	Name="Rec-21 Blueprint";
	Product="rec21";
	Duration=hourSec;
	SellPrice=6000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=45000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=400;};
		{Type="Item"; ItemId="metal"; Amount=300;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
		{Type="Item"; ItemId="glass"; Amount=100;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="at4bp";
	Name="AT4 Rocket Launcher Blueprint";
	Product="at4";
	Duration=daySec;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=60000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Stat"; Name="Level"; Amount=260;};
		{Type="Item"; ItemId="metal"; Amount=400;};
		{Type="Item"; ItemId="at4parts"; Amount=3;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="sr308bp";
	Name="SR-308 Blueprint";
	Product="sr308";
	Duration=daySec;
	SellPrice=8000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=50000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Stat"; Name="Level"; Amount=420;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="glass"; Amount=40;};
		{Type="Item"; ItemId="sr308parts"; Amount=3;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="deaglebp";
	Name="Desert Eagle Blueprint";
	Product="deagle";
	Duration=daySec;
	SellPrice=320;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=30000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Item"; ItemId="metal"; Amount=80;};
		{Type="Item"; ItemId="deagleparts"; Amount=3;};
	};
	Category="Weapons";
};

BlueprintLibrary.New{
	Id="vectorxbp";
	Name="Vector X Blueprint";
	Product="vectorx";
	Duration=daySec;
	SellPrice=28800;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=20000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Stat"; Name="Level"; Amount=350;};
		{Type="Item"; ItemId="metal"; Amount=300;};
		{Type="Item"; ItemId="glass"; Amount=200;};
		{Type="Item"; ItemId="steelfragments"; Amount=20;};
		{Type="Item"; ItemId="vectorxparts"; Amount=3;};
	};
	Category="Weapons";
};


BlueprintLibrary.New{
	Id="rusty48bp";
	Name="Rusty 48 Blueprint";
	Product="rusty48";
	Duration=daySec;
	SellPrice=28800;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=30000;};
		{Type="Stat"; Name="Perks"; Amount=20;};
		{Type="Stat"; Name="Level"; Amount=440;};
		{Type="Item"; ItemId="metal"; Amount=200;};
		{Type="Item"; ItemId="wood"; Amount=50;};
		{Type="Item"; ItemId="gears"; Amount=3;};
		{Type="Item"; ItemId="rusty48parts"; Amount=3;};
	};
	Category="Weapons";
};


BlueprintLibrary.New{
	Id="arelshiftcrossbp";
	Name="Arelshift Cross Blueprint";
	Product="arelshiftcross";
	Duration=daySec;
	SellPrice=35000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=30000;};
		{Type="Stat"; Name="Perks"; Amount=100;};
		{Type="Stat"; Name="Level"; Amount=460;};
		
		{Type="Item"; ItemId="metal"; Amount=300;};
		{Type="Item"; ItemId="glass"; Amount=100;};
		
		{Type="Item"; ItemId="gears"; Amount=2;};
		{Type="Item"; ItemId="rope"; Amount=3;};
		
		
		{Type="Item"; ItemId="arelshiftcrossparts"; Amount=3;};
	};
	Category="Weapons";
};


--== MARK: Melee
BlueprintLibrary.New{
	Id="chainsawbp";
	Name="Chainsaw Blueprint";
	Product="chainsaw";
	Duration=hourSec;
	SellPrice=2000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=13000;};
		{Type="Stat"; Name="Perks"; Amount=10;};
		{Type="Stat"; Name="Level"; Amount=300;};
		{Type="Item"; ItemId="metal"; Amount=100;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="motor"; Amount=1;};
	};
	Category="Weapons";
};


--== MARK: Clothing
BlueprintLibrary.New{
	Id="brownbeltbp";
	Name="Tactical Belt Blueprint";
	Product="brownbelt";
	Duration=600;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=2300;};
		{Type="Item"; ItemId="cloth"; Amount=60;};
		{Type="Item"; ItemId="metal"; Amount=20;};
	};
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="brownbootsbp";
	Name="Brown Leather Boots Blueprint";
	Product="brownleatherboots";
	Duration=600;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=3000;};
		{Type="Item"; ItemId="cloth"; Amount=80;};
		{Type="Item"; ItemId="metal"; Amount=10;};
	};
	Category="Clothing";
	Tags={"Unobtainable";};
};

BlueprintLibrary.New{
	Id="labcoatbp";
	Name="Lab Coat Blueprint";
	Product="labcoat";
	Duration=600;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=6000;};
		{Type="Item"; ItemId="cloth"; Amount=160;};
		{Type="Item"; ItemId="metal"; Amount=10;};
	};
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="greytshirtbp";
	Name="Grey T-Shirt Blueprint";
	Product="greytshirt";
	Duration=60;
	Requirements={
		{Type="Item"; ItemId="cloth"; Amount=85;};
	};
	Category="Clothing";
	Sources={"Obtained from <b>RAT Shop</b>";};
};

BlueprintLibrary.New{
	Id="watchbp";
	Name="Watch Blueprint";
	Product="watch";
	Duration=60;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=40;};
		{Type="Item"; ItemId="cloth"; Amount=10;};
	};
	Category="Clothing";
	Sources={"Obtained from <b>RAT Shop</b>";};
};

BlueprintLibrary.New{
	Id="plankarmorbp";
	Name="Plank Armor Blueprint";
	Product="plankarmor";
	Duration=300;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=3000;};
		{Type="Item"; ItemId="cloth"; Amount=20;};
		{Type="Item"; ItemId="wood"; Amount=40;};
	};
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="scraparmorbp";
	Name="Scrap Armor Blueprint";
	Product="scraparmor";
	Duration=600;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=4000;};
		{Type="Item"; ItemId="cloth"; Amount=10;};
		{Type="Item"; ItemId="metal"; Amount=200;};
	};
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="militarybootsbp";
	Name="Military Boots Blueprint";
	Product="militaryboots";
	Duration=300;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=5000;};
		{Type="Item"; ItemId="cloth"; Amount=120;};
		{Type="Item"; ItemId="metal"; Amount=50;};
	};
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="divinggogglesbp";
	Name="Diving Goggles Blueprint";
	Product="divinggoggles";
	Duration=600;
	SellPrice=1000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=6000;};
		{Type="Item"; ItemId="cloth"; Amount=200;};
		{Type="Item"; ItemId="glass"; Amount=80;};
	};
	Category="Clothing";
	Sources={"Obtained from <b>RAT Shop</b>";};
};

BlueprintLibrary.New{
	Id="nekrostrenchbp";
	Name="Nekros Trench Coat Blueprint";
	Product="nekrostrench";
	Duration=hourSec;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=15000;};
		
		{Type="Item"; ItemId="cloth"; Amount=400;};
		{Type="Item"; ItemId="nekronscales"; Amount=200;};
		
		{Type="Item"; ItemId="nekronparticulate"; Amount=20;};
	};
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="portableautoturretbp";
	Name="Portable Auto Turret Blueprint";
	Product="portableautoturret";
	Duration=300;
	SellPrice=90000;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=45000;};
		{Type="Stat"; Name="Perks"; Amount=100;};
		{Type="Stat"; Name="Level"; Amount=420;};
		
		{Type="Item"; ItemId="cloth"; Amount=50;};
		{Type="Item"; ItemId="steelfragments"; Amount=20;};
		{Type="Item"; ItemId="gears"; Amount=5;};
	};
	Sources={"Obtained from <b>Mysterious Engineer</b>";};
	TradingTax=9900;
	Category="Clothing";
};

BlueprintLibrary.New{
	Id="tirearmorbp";
	Name="Tire Armor Blueprint";
	Product="tirearmor";
	Duration=hourSec;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=20000;};

		{Type="Item"; ItemId="cloth"; Amount=100;};
		{Type="Item"; ItemId="adhesive"; Amount=200;};
		{Type="Item"; ItemId="tires"; Amount=4;};
		
	};
	Category="Clothing";
};


--== MARK: Commodity
BlueprintLibrary.New{
	Id="chargerbp";
	Name="Charger Blueprint";
	Product="charger";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=20;};
		{Type="Item"; ItemId="battery"; Amount=2;};
		{Type="Item"; ItemId="wires"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="portablestovebp";
	Name="Portable Stove Blueprint";
	Product="portablestove";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="wood"; Amount=5;};
		{Type="Item"; ItemId="metalpipes"; Amount=2;};
		{Type="Item"; ItemId="igniter"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="lanternbp";
	Name="Lantern Blueprint";
	Product="lantern";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=30;};
		{Type="Item"; ItemId="igniter"; Amount=1;};
		{Type="Item"; ItemId="gastank"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="handgeneratorbp";
	Name="Hand Crank Generator Blueprint";
	Product="handgenerator";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="wires"; Amount=1;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="motor"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="walkietalkiebp";
	Name="Walkie Talkie Blueprint";
	Product="walkietalkie";
	Duration=60;
	SellPrice=50;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="wires"; Amount=1;};
		{Type="Item"; ItemId="circuitboards"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="spotlightbp";
	Name="Spotlight Blueprint";
	Product="spotlight";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="wires"; Amount=1;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="lightbulb"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="musicboxbp";
	Name="Music Box Blueprint";
	Product="musicbox";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=10;};
		{Type="Item"; ItemId="wood"; Amount=5;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="wires"; Amount=1;};
		{Type="Item"; ItemId="motor"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="binocularsbp";
	Name="Binoculars Blueprint";
	Product="binoculars";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=10;};
		{Type="Item"; ItemId="glass"; Amount=20;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="boomboxbp";
	Name="Boombox Blueprint";
	Product="boombox";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="metalpipes"; Amount=1;};
		{Type="Item"; ItemId="battery"; Amount=1;};
		{Type="Item"; ItemId="wires"; Amount=1;};
	};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="wateringcanbp";
	Name="Watering Can Blueprint";
	Product="wateringcan";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
	};
	Sources={"Obtained from <b>Joseph in Mission: Joseph's Lettuce</b>";};
	Category="Commodities";
};

BlueprintLibrary.New{
	Id="ladderbp";
	Name="Ladder Blueprint";
	Product="ladder";
	Duration=60;
	SellPrice=100;
	Requirements={
		{Type="Item"; ItemId="steelfragments"; Amount=20;};
	};
	Sources={"Obtained from <b>David in The Harbor</b>";};
	Category="Commodities";
};


--== MARK: Summons
BlueprintLibrary.New{
	Id="nekronparticulatecachebp";
	Name="Nekron Particulate Cache Blueprint";
	Product="nekronparticulatecache";
	Amount=1;
	Duration=60;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=50;};
		{Type="Item"; ItemId="nekronparticulate"; Amount=4;};
	};
	Category="Summons";
};


--== MARK: Structures
BlueprintLibrary.New{
	Id="metalbarricadebp";
	Name="Metal Barricade Blueprint";
	Product="metalbarricade";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=45};
		{Type="Item"; ItemId="wood"; Amount=5};
		{Type="Item"; ItemId="screws"; Amount=20};
	};
	Category="Structures";
	Sources={"Dropped from Zombies during horde attacks.";};
};

BlueprintLibrary.New{
	Id="scarecrowbp";
	Name="Scarecrow Blueprint";
	Product="scarecrow";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=1000;};
		{Type="Item"; ItemId="wood"; Amount=10};
		{Type="Item"; ItemId="battery"; Amount=2;};
		{Type="Item"; ItemId="screws"; Amount=50};
	};
	Category="Structures";
	Sources={"Dropped from Zombies during horde attacks.";};
};

BlueprintLibrary.New{
	Id="gastankiedbp";
	Name="Gas Tank IED Blueprint";
	Product="gastankied";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=5000;};
		{Type="Item"; ItemId="igniter"; Amount=2};
		{Type="Item"; ItemId="wires"; Amount=2;};
		{Type="Item"; ItemId="gastank"; Amount=2;};
		{Type="Item"; ItemId="screws"; Amount=10};
	};
	Category="Structures";
	Sources={"Dropped from Zombies during horde attacks.";};
};

BlueprintLibrary.New{
	Id="barbedwoodenbp";
	Name="Barbed Wooden Fence Blueprint";
	Product="barbedwooden";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=20};
		{Type="Item"; ItemId="wood"; Amount=2};
		{Type="Item"; ItemId="screws"; Amount=30};
	};
	Category="Structures";
};

BlueprintLibrary.New{
	Id="ticksnaretrapbp";
	Name="Tick Snare Trap Blueprint";
	Product="ticksnaretrap";
	Duration=60;
	SellPrice=200;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=500;};
		{Type="Item"; ItemId="metal"; Amount=40};
		{Type="Item"; ItemId="rope"; Amount=3};
	};
	Category="Structures";
};

BlueprintLibrary.New{
	Id="barbedmetalbp";
	Name="Barbed Metal Fence Blueprint";
	Product="barbedmetal";
	Duration=60;
	SellPrice=500;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=1000;};
		{Type="Item"; ItemId="metal"; Amount=100};
		{Type="Item"; ItemId="screws"; Amount=50};
	};
	Category="Structures";
};

--== MARK: Resource Packages

local resourcePackagesLib = Lib:ListByKeyValue("ResourceItemId", function(v) return v ~= nil; end);
for a=1, #resourcePackagesLib do
	local itemLib = resourcePackagesLib[a];
	local resourceItemId = itemLib.ResourceItemId;
	local resourceItemLib = modItemsLibrary:Find(resourceItemId);

	BlueprintLibrary.New{
		Id=itemLib.Id .."bp";
		Name=itemLib.Name .." Blueprint";
		Product=itemLib.Id;
		Duration=60;
		SellPrice=2000;
		Requirements={
			{Type="Stat"; Name="Perks"; Amount=25;};
			{Type="Item"; ItemId=resourceItemId; Amount=resourceItemLib.Stackable;};
		};
		Category="Resource Packages";
	};
end


--== MARK: Resources
BlueprintLibrary.New{
	Id="t1keybp";
	Name="Tier 1 Key Blueprint";
	Product="t1key";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=5000;};
		{Type="Item"; ItemId="metal"; Amount=25};
		{Type="Item"; ItemId="glass"; Amount=25};
	};
	Disabled=true;
	Tags={"Unobtainable"};
	CanUnlock=false;
};

BlueprintLibrary.New{
	Id="t2keybp";
	Name="Tier 2 Key Blueprint";
	Product="t2key";
	Duration=60;
	Requirements={
		{Type="Stat"; Name="Money"; Amount=10000;};
		{Type="Item"; ItemId="metal"; Amount=40};
		{Type="Item"; ItemId="wood"; Amount=25};
	};
	Disabled=true;
	Tags={"Unobtainable"};
	CanUnlock=false;
};

BlueprintLibrary.New{
	Id="gunpowderbp";
	Name="Gun Powder Blueprint";
	Product="gunpowder";
	Duration=10;
	Amount=25;
	Requirements={
		{Type="Item"; ItemId="coal"; Amount=25};
		{Type="Item"; ItemId="sulfur"; Amount=25};
	};
	CanUnlock=true;
	Category = "Miscellaneous";
};

BlueprintLibrary.New{
	Id="ammoboxbp";
	Name="Ammo Box Blueprint";
	Product="ammobox";
	Duration=10;
	Requirements={
		{Type="Item"; ItemId="metal"; Amount=100};
		{Type="Item"; ItemId="gunpowder"; Amount=25};
	};
	CanUnlock=true;
	Category = "Miscellaneous";
};



BlueprintLibrary.Library = library;
return BlueprintLibrary;