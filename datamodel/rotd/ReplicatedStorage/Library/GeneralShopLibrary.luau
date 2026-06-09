local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);

local ShopLibrary = {
	AmmunitionCurrency = nil;
};

--
local SELL_PRICES = {
	["Tier1"]=300;
	
	["metal"]=1;
	["glass"]=1;
	["wood"]=1;
	["cloth"]=1;
	["screws"]=1;
	["adhesive"]=1;
	
	["cannedbeans"]=48;
	["chocobar"]=48;
	["cannedfish"]=1452;
	["sandwich"]=120;
	["ziphoningserum"]=2000;
	
	["metalpipes"] = 200;
	["igniter"] = 200;
	["gastank"] = 200;
	["wires"] = 200;

	["battery"] = 400;
	["motor"] = 400;
	
	["circuitboards"] = 800;
	["lightbulb"] = 800;
	["radiator"] = 800;
	["toxiccontainer"] = 800;
	["gears"] = 800;
	["rope"] = 800;
	["tires"] = 800;
	
	-- util
	["matchbox"] = 800;
	["binoculars"] = 400; -- buy $500
	
	["gps"] = 650; -- buy $1k
	["rcetablet"] = 5000; -- buy $10k
	["wateringcan"] = 500;
	["disguisekit"] = 800;
	["ladder"] = 1000;
	
	["coal"]=12;
	
	["purplelemon"]=500;
	["fotlcardgame"]=3000;
	
	-- Weapon parts;
	["tacticalbowparts"]=500;
	["at4parts"]=600;
	["sr308parts"]=700;
	["vectorxparts"]=800;
	["rusty48parts"]=1000;
	["arelshiftcrossparts"]=1000;
	["deagleparts"]=1200;
	["grandgarandparts1"]=1400;
	["grandgarandparts2"]=1400;
	["grandgarandparts3"]=1400;
	["rechamber1216parts1"]=1600;
	["rechamber1216parts2"]=1600;
	["rechamber1216parts3"]=1600;
	["dualuziparts1"]=1600;
	["dualuziparts2"]=1600;
	["dualuziparts3"]=1600;

	--
	["wantedposter"]=1000;
	
	-- Events
	["halloweencandy"]=5;
};
ShopLibrary.SellPrice = SELL_PRICES;

SELL_PRICES["lantern"] = (SELL_PRICES.igniter + SELL_PRICES.gastank) * 2.5; -- 1'000
SELL_PRICES["walkietalkie"] = (SELL_PRICES.wires + SELL_PRICES.circuitboards) *2.2; -- 2'200
SELL_PRICES["musicbox"] = (SELL_PRICES.battery + SELL_PRICES.wires + SELL_PRICES.motor) *2.4; -- 2'400
SELL_PRICES["spotlight"] = (SELL_PRICES.wires + SELL_PRICES.battery + SELL_PRICES.lightbulb) *1.75; -- 2'450
SELL_PRICES["boombox"] = (SELL_PRICES.metalpipes + SELL_PRICES.wires + SELL_PRICES.battery) * 2.2; -- 1'760

SELL_PRICES["portablestove"] = (SELL_PRICES.metalpipes*2 + SELL_PRICES.igniter) * 7.2; -- 4'320
SELL_PRICES["charger"] = (SELL_PRICES.battery*2 + SELL_PRICES.wires) * 4.8; -- 4'800
SELL_PRICES["handgenerator"] = (SELL_PRICES.wires + SELL_PRICES.battery + SELL_PRICES.motor) * 4.3; -- 4'300
SELL_PRICES["solarconcentrator"] = (SELL_PRICES.metalpipes + SELL_PRICES.gears) * 4.6; -- 4'600
SELL_PRICES["fermentationvat"] = (SELL_PRICES.lightbulb + SELL_PRICES.toxiccontainer) * 2.8; -- 4'480
SELL_PRICES["hydroponiccapsule"] = (SELL_PRICES.metalpipes + SELL_PRICES.toxiccontainer + SELL_PRICES.tires) * 2.3; -- 4'140
SELL_PRICES["pulleymechanics"] = (SELL_PRICES.gears + SELL_PRICES.tires + SELL_PRICES.rope) * 2; -- 4'800

SELL_PRICES["biocharkiln"] = (SELL_PRICES.gastank + SELL_PRICES.portablestove + SELL_PRICES.radiator) * 2.9; -- 15'428
SELL_PRICES["bicyclepoweredgenerator"] = (SELL_PRICES.handgenerator + SELL_PRICES.pulleymechanics) * 1.8; -- 16'380
SELL_PRICES["solarwaterstill"] = (SELL_PRICES.gears + SELL_PRICES.solarconcentrator + SELL_PRICES.metalpipes) * 2.7; -- 15'120


ShopLibrary.AmmunitionPrice = {
	["p250"]=0;
	["cz75"]=1;
	["xm1014"]=3;
	["sawedoff"]=2;
	["mp5"]=3;
	["mp7"]=3;
	["tec9"]=6;
	["deagle"]=8;
	["m4a4"]=13;
	["ak47"]=14;
	["awp"]=35;
	["minigun"]=60;
	["flamethrower"]=42;

	["m9legacy"]=42;
	["grenadelauncher"]=60;
	["dualp250"]=20;
	["revolver454"]=40;
	["mariner590"]=22;
	["czevo3"]=24;
	["fnfal"]=13;
	["tacticalbow"]=8;
	["desolatorheavy"]=90;
	["rec21"]=28;
	["at4"]=30;
	["sr308"]=26;
	["vectorx"]=80;
	
	["rusty48"]=100;
	["arelshiftcross"]=74;

	["grandgarand"]=88;
	["dualuzi"]=88;
	["rechamber1216"]=88;
}

ShopLibrary.RepairPrice = {
	["disguisekit"]=200;
	["divinggoggles"]=400;
	["gasmask"]=1000;
	["hazmathood"]=1000;
};

ShopLibrary.Pages = {
	["Item Codex"]={
		Order=1;
		Type="Page";
		Id="CatalogPage";
		Title="Catalog";
		Icon="rbxassetid://6122866034";
		Desc="• Encyclopedia of all items. Items no longer obtainable will only show if you have obtained them before.";
	};
	Money = {
		Order=2;
		FrontPage = {
			{
				Type="Page";
				Id="WeaponBpPage";
				Title="Weapon Blueprints";
				Icon="rbxassetid://5166150878";
				Desc="• Blueprints for making weapons!";
			};
			{
				Type="Page";
				Id="ModBpPage";
				Title="Mod Blueprints";
				Icon="rbxassetid://3817463645";
				Desc="• Blueprints for making weapon mods!";
			};
			{
				Type="Page";
				Id="ClothingBpPage";
				Title="Clothing Blueprints";
				Icon="rbxassetid://5756503297";
				Desc="• Blueprints for different types of clothing!";
			};
			{
				Type="Page";
				Id="AccessoriesPage";
				Title="Accessories";
				Icon="rbxassetid://5932231243";
				Desc="• Useful items!";
			};
			{
				Type="Page";
				Id="SummonsPage";
				Title="Summons";
				Icon="rbxassetid://11154552175";
				Desc="• Items to summon bosses, such as hard mode Bandit Helicopter boss!";
			};
			
		};
		
		
		WeaponBpPage = {
			{Type="Product"; Id="cz75bp"};
			{Type="Product"; Id="xm1014bp"};
			{Type="Product"; Id="mp5bp"};
		};
		
		ModBpPage = {
			{Type="Product"; Id="pistoldamagebp"};
			{Type="Product"; Id="pistolfireratebp"};
			
			{Type="Product"; Id="pistolreloadspeedbp"};
			{Type="Product"; Id="pistolammocapbp"};
			
			{Type="Product"; Id="shotgunreloadspeedbp"};
			{Type="Product"; Id="shotgunammocapbp"};
		};
		
		ClothingBpPage = {
			{Type="Product"; Id="greytshirtbp"};
			{Type="Product"; Id="watchbp"};
			{Type="Product"; Id="divinggogglesbp"};
		};
		
		AccessoriesPage = {
			{Type="Product"; Id="binoculars"};
			{Type="Product"; Id="gps"};
			{Type="Product"; Id="lantern"};
			{Type="Product"; Id="boombox"};
			{Type="Product"; Id="fireworks"};
			{Type="Product"; Id="rcetablet"};
			{Type="Product"; Id="entityleash"};
			
		};
		
		SummonsPage = {
			{Type="Product"; Id="zricerahornbp"};
			{Type="Product"; Id="vexlingbp"};
			{Type="Product"; Id="nekronparticulatecachebp"};
		}
	};
	
	Perks = {
		Order=3;
		FrontPage = {
			{
				Type="Page";
				Id="WeaponsPage";
				Title="Weapons";
				Icon="rbxassetid://5175211604";
				Desc="• Pre-made weapons!";
			};
			{
				Type="Page";
				Id="ModsPage";
				Title="Mods";
				Icon="rbxassetid://4573247953";
				Desc="• Rare mods!";
			};
			
			--== Rats' Only
			{
				ShopType="Rats";
				Type="Page";
				Id="RatsSpecialPage";
				Title="Rat's Special";
				Icon="rbxassetid://11809270023";
				Desc="• Special R.A.T. items and blueprints!";
			};
			
			--== Bandits' Special
			{
				ShopType="Bandits";
				Type="Page";
				Id="BanditsSpecialPage";
				Title="Bandit's Special";
				Icon="rbxassetid://11809270023";
				Desc="• Special Bandits items and blueprints!";
			};
		};

		RatsSpecialPage = {
			{Type="Product"; Id="metalpackagebp"};
			{Type="Product"; Id="clothpackagebp"};
			{Type="Product"; Id="wantedposter"; Desc="A wanted poster of a random safehome NPC. This item can be given to Patrick to guarantee the next survivor from \"Another Survivor\".";};

			{Type="Product"; Id="pistolhappyautomod"};
			{Type="Product"; Id="shotgunhappyautomod"};
		};
		
		BanditsSpecialPage = {
			{Type="Product"; Id="tacticalbowbp"};
			{Type="Product"; Id="vectorxbp"};
			{Type="Product"; Id="glasspackagebp"};
			{Type="Product"; Id="woodpackagebp"};
			{Type="Product"; Id="gunpowderbp"};
			{Type="Product"; Id="ammoboxbp"};
			
		};
		
		WeaponsPage = {
			{Type="Product"; Id="p250"};
			{Type="Product"; Id="cz75"};
			{Type="Product"; Id="tec9"};
			{Type="Product"; Id="xm1014"};
			{Type="Product"; Id="mp5"};
			--{Type="Product"; Id="deagle"};
			{Type="Product"; Id="sawedoff"};
			{Type="Product"; Id="mp7"};
			{Type="Product"; Id="m4a4"};
			{Type="Product"; Id="ak47"};
			{Type="Product"; Id="awp"};
			{Type="Product"; Id="minigun"};
			{Type="Product"; Id="flamethrower"};
			{Type="Product"; Id="mariner590"};
			{Type="Product"; Id="fnfal"};
		};
		
		ModsPage = {
			{Type="Product"; Id="incendiarymod"};
			{Type="Product"; Id="electricmod"};
			{Type="Product"; Id="frostmod"};
			{Type="Product"; Id="toxicmod"};
			
			{Type="Product"; Id="sniperfocusrate"};
			{Type="Product"; Id="pistolammomagmod"};
			{Type="Product"; Id="pistolreloadspeedmod"};
		};
	};
	
	Leaderboards = {
		Order=4;
		FrontPage = {
			{
				Type="Page";
				Id="MissionPassLbPage";
				Title="Event Pass";
				Icon="rbxassetid://2938848546";
				Desc="• Leaderboard for the event pass levels!";
			};
			{
				Type="Page";
				Id="DonationPage";
				Title="Donations";
				Icon="http://www.roblox.com/asset/?id=4728295860";
				Desc="• Leaderboard for the top donators!";
			};
			{
				Type="Page";
				Id="lbZombiesPage";
				Title="Zombie Kills";
				Icon="rbxassetid://2938848546";
				Desc="• Leaderboard for the top zombie kills!";
			};

		};
	};
};

--=====================================================================================================================================
ShopLibrary.Products = modLibraryManager.new();

--== Weapon Blueprints;
ShopLibrary.Products:Add{Id="cz75bp"; Currency="Money"; Price=100;};
ShopLibrary.Products:Add{Id="xm1014bp"; Currency="Money"; Price=600;};--300
ShopLibrary.Products:Add{Id="mp5bp"; Currency="Money"; Price=1000;};--900

ShopLibrary.Products:Add{Id="tacticalbowbp"; Currency="Perks"; Price=100;};
ShopLibrary.Products:Add{Id="vectorxbp"; Currency="Perks"; Price=400;};

--== Weapons;
ShopLibrary.Products:Add{Id="p250"; Currency="Perks"; Price=25;};
ShopLibrary.Products:Add{Id="cz75"; Currency="Perks"; Price=50;};
ShopLibrary.Products:Add{Id="tec9"; Currency="Perks"; Price=100;};
ShopLibrary.Products:Add{Id="xm1014"; Currency="Perks"; Price=100;};
ShopLibrary.Products:Add{Id="mp5"; Currency="Perks"; Price=100;};
--ShopLibrary.Products:Add{Id="deagle"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="sawedoff"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="mp7"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="m4a4"; Currency="Perks"; Price=500;};
ShopLibrary.Products:Add{Id="ak47"; Currency="Perks"; Price=500;};
ShopLibrary.Products:Add{Id="awp"; Currency="Perks"; Price=1000;};
ShopLibrary.Products:Add{Id="minigun"; Currency="Perks"; Price=1000;};
ShopLibrary.Products:Add{Id="flamethrower"; Currency="Perks"; Price=1000;};
ShopLibrary.Products:Add{Id="mariner590"; Currency="Perks"; Price=2000;};
ShopLibrary.Products:Add{Id="fnfal"; Currency="Perks"; Price=2000;};

--== Clothing;
ShopLibrary.Products:Add{Id="greytshirtbp"; Currency="Money"; Price=600;};
ShopLibrary.Products:Add{Id="watchbp"; Currency="Money"; Price=1000;};
ShopLibrary.Products:Add{Id="divinggogglesbp"; Currency="Money"; Price=3000;};

--== Accessories;
ShopLibrary.Products:Add{Id="binoculars"; Currency="Money"; Price=500;};
ShopLibrary.Products:Add{Id="gps"; Currency="Money"; Price=1000;};
ShopLibrary.Products:Add{Id="fireworks"; Currency="Money"; Price=1000;};
ShopLibrary.Products:Add{Id="lantern"; Currency="Money"; Price= math.floor(SELL_PRICES["lantern"]*1.5/10)*10; };
ShopLibrary.Products:Add{Id="boombox"; Currency="Money"; Price= math.floor(SELL_PRICES["boombox"]*1.5/10)*10; };
ShopLibrary.Products:Add{Id="spotlight"; Currency="Money"; Price= math.floor(SELL_PRICES["spotlight"]*1.5/10)*10; };
ShopLibrary.Products:Add{Id="rcetablet"; Currency="Money"; Price=10000;};

ShopLibrary.Products:Add{Id="entityleash"; Currency="Perks"; Price=100;};

--== Summons;

ShopLibrary.Products:Add{Id="zricerahornbp"; Currency="Money"; Price=4000;};
ShopLibrary.Products:Add{Id="vexlingbp"; Currency="Money"; Price=8000;};
ShopLibrary.Products:Add{Id="nekronparticulatecachebp"; Currency="Money"; Price=12000;};


--== Mods Blueprints;
ShopLibrary.Products:Add{Id="pistoldamagebp"; Currency="Money"; Price=ShopLibrary.SellPrice.Tier1+200;};
ShopLibrary.Products:Add{Id="pistolfireratebp"; Currency="Money"; Price=ShopLibrary.SellPrice.Tier1+300;};
ShopLibrary.Products:Add{Id="pistolreloadspeedbp"; Currency="Money"; Price=ShopLibrary.SellPrice.Tier1+400;};
ShopLibrary.Products:Add{Id="pistolammocapbp"; Currency="Money"; Price=ShopLibrary.SellPrice.Tier1+500;};
ShopLibrary.Products:Add{Id="shotgunreloadspeedbp"; Currency="Money"; Price=ShopLibrary.SellPrice.Tier1+500;};
ShopLibrary.Products:Add{Id="shotgunammocapbp"; Currency="Money"; Price=ShopLibrary.SellPrice.Tier1+500;};

--== Mods;
ShopLibrary.Products:Add{Id="pistolreloadspeedmod"; Currency="Perks"; Price=25;};
ShopLibrary.Products:Add{Id="pistolammomagmod"; Currency="Perks"; Price=25;};
ShopLibrary.Products:Add{Id="sniperfocusrate"; Currency="Perks"; Price=25;};

ShopLibrary.Products:Add{Id="incendiarymod"; Currency="Perks"; Price=50;};
ShopLibrary.Products:Add{Id="electricmod"; Currency="Perks"; Price=50;};
ShopLibrary.Products:Add{Id="frostmod"; Currency="Perks"; Price=50;};
ShopLibrary.Products:Add{Id="toxicmod"; Currency="Perks"; Price=50;};

ShopLibrary.Products:Add{Id="pistolhappyautomod"; Currency="Perks"; Price=50;};
ShopLibrary.Products:Add{Id="shotgunhappyautomod"; Currency="Perks"; Price=50;};

--== Resource Package bp
ShopLibrary.Products:Add{Id="metalpackagebp"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="clothpackagebp"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="glasspackagebp"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="woodpackagebp"; Currency="Perks"; Price=200;};


--== Misc Blueprints
ShopLibrary.Products:Add{Id="gunpowderbp"; Currency="Perks"; Price=200;};
ShopLibrary.Products:Add{Id="ammoboxbp"; Currency="Perks"; Price=200;};

ShopLibrary.Products:Add{Id="wantedposter"; Currency="Perks"; Price=25;};

--====================================

function ShopLibrary.CalculateAmmoPrice(itemId, values, config, maxPrice, doublePenalty)
	local ammo = values.A or config.AmmoLimit;
	local maxAmmo = values.MA or config.MaxAmmoLimit;
	
	local totalAmmoNeeded = (config.AmmoLimit-ammo)+(config.MaxAmmoLimit-maxAmmo);
	local pricePerMag = ShopLibrary.AmmunitionPrice[itemId] or 0;
	
	local totalMagsNeeded = math.ceil(totalAmmoNeeded/config.AmmoLimit);
	local ammoPrice = math.ceil(pricePerMag*totalMagsNeeded);
	
	while (ammoPrice > maxPrice and (totalMagsNeeded-1) <= 0) do
		totalMagsNeeded = math.ceil(totalMagsNeeded -1);
		ammoPrice = math.ceil(pricePerMag*totalMagsNeeded);
	end
	
	ammoPrice = math.clamp(ammoPrice, 0, math.huge);
	if doublePenalty == true then ammoPrice = ammoPrice *2 end;
	totalMagsNeeded = math.clamp(totalMagsNeeded, 1, math.huge);
	return ammoPrice, totalMagsNeeded;
end

-- PurchaseReplies.Success
ShopLibrary.PurchaseReplies = setmetatable({
	Success = 0;
	InsufficientCurrency = 1;
	TooFar = 2;
	InvalidProduct = 3;
	ShopClosed = 4;
	TooSoon=5;
	InvalidItem=6;
	InventoryFull=7;
	PremiumRequired=8;
	ExhaustedUses=9;
}, {__index={
	"Not enough $Currency";
	"You are too far from shop";
	"Invalid Product";
	"Shop is closed";
	"Woah there";
	"Invalid Item";
	"Inventory Full";
	"Requires Premium";
	"Exhausted Uses";
};});

return ShopLibrary;