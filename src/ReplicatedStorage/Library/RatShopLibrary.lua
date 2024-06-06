local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local ShopLibrary = {
	AmmunitionCurrency = nil;
};

--
ShopLibrary.SellPrice = {
	["Tier1"]=50;
	
	["metal"]=5;
	["glass"]=5;
	["wood"]=5;
	["cloth"]=5;
	["screws"]=5;
	["adhesive"]=5;
	
	["cannedbeans"]=24;
	["chocobar"]=24;
	["cannedfish"]=1200;
	
	["metalpipes"]=200;
	["igniter"]=200; --300
	["gastank"]=200;
	
	["wires"]=400;
	["battery"]=400;
	["motor"]=400;
	
	["circuitboards"]=800;
	["lightbulb"]=800;
	["radiator"]=800;
	["toxiccontainer"]=800;
	["gears"]=800;
	["rope"]=800;
	["tires"]=800;
	
	["binoculars"]=400;
	["lantern"]=1000;
	["portablestove"]=3300;
	["charger"]=4700;
	["handgenerator"]=5910;
	
	["walkietalkie"]=9100;
	["spotlight"]=4000;
	["musicbox"]=7000;
	["boombox"]=2300;
	["wateringcan"]=3000;
	["disguisekit"]=3400;
	["gps"]=650;
	["matchbox"]=2100;
	["ladder"]=5000;
	["rcetablet"]=5000;
	
	["coal"]=64;
	
	["purplelemon"]=12500; --10500
	["fotlcardgame"]=14000;
	
	-- Weapon parts;
	["tacticalbowparts"]=2000;
	["at4parts"]=3000;
	["sr308parts"]=4000;
	["vectorxparts"]=5000;
	["rusty48parts"]=6000;
	["arelshiftcrossparts"]=7000;
	["deagleparts"]=5000;
	
	--
	["wantedposter"]=1000;
	
	-- Events
	["halloweencandy"]=5;
};

ShopLibrary.AmmunitionPrice = {
	["p250"]=0;
	["cz75"]=2;
	["xm1014"]=6;
	["sawedoff"]=4;
	["mp5"]=7;
	["mp7"]=7;
	["tec9"]=12;
	["deagle"]=16;
	["m4a4"]=26;
	["ak47"]=28;
	["awp"]=75;
	["minigun"]=120;
	["flamethrower"]=95;
	["m9legacy"]=85;
	
	["grenadelauncher"]=120;
	["dualp250"]=40;
	["revolver454"]=80;
	["mariner590"]=45;
	["czevo3"]=48;
	["fnfal"]=26;
	["tacticalbow"]=16;
	["desolatorheavy"]=180;
	["rec21"]=55;
	["at4"]=60;
	["sr308"]=52;
	["vectorx"]=160;
	
	["rusty48"]=200;
	["arelshiftcross"]=148;
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
			{Type="Product"; Id="spotlight"};
			{Type="Product"; Id="fireworks"};
			{Type="Product"; Id="rcetablet"};
			{Type="Product"; Id="entityleash"};
			
		};
		
		SummonsPage = {
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

--== Clothing;
ShopLibrary.Products:Add{Id="greytshirtbp"; Currency="Money"; Price=600;};
ShopLibrary.Products:Add{Id="watchbp"; Currency="Money"; Price=1000;};
ShopLibrary.Products:Add{Id="divinggogglesbp"; Currency="Money"; Price=3000;};

--== Accessories;
ShopLibrary.Products:Add{Id="binoculars"; Currency="Money"; Price=500;};
ShopLibrary.Products:Add{Id="gps"; Currency="Money"; Price=1000;};
ShopLibrary.Products:Add{Id="fireworks"; Currency="Money"; Price=1000;};
ShopLibrary.Products:Add{Id="lantern"; Currency="Money"; Price=1600;};
ShopLibrary.Products:Add{Id="boombox"; Currency="Money"; Price=3000;};
ShopLibrary.Products:Add{Id="spotlight"; Currency="Money"; Price=5000;};
ShopLibrary.Products:Add{Id="rcetablet"; Currency="Money"; Price=10000;};

ShopLibrary.Products:Add{Id="entityleash"; Currency="Perks"; Price=100;};

--== Summons;
ShopLibrary.Products:Add{Id="nekronparticulatecachebp"; Currency="Money"; Price=20000;};


--== Mods Blueprints;
ShopLibrary.Products:Add{Id="pistoldamagebp"; Currency="Money"; Price=200;};
ShopLibrary.Products:Add{Id="pistolfireratebp"; Currency="Money"; Price=300;};
ShopLibrary.Products:Add{Id="pistolreloadspeedbp"; Currency="Money"; Price=400;};
ShopLibrary.Products:Add{Id="pistolammocapbp"; Currency="Money"; Price=500;};
ShopLibrary.Products:Add{Id="shotgunreloadspeedbp"; Currency="Money"; Price=500;};
ShopLibrary.Products:Add{Id="shotgunammocapbp"; Currency="Money"; Price=500;};

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
	local pricePerMag = ShopLibrary.AmmunitionPrice[itemId] or 1;
	
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