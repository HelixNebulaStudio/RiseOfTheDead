local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local GoldShopLibrary = {};
GoldShopLibrary.ShopSaleSign = false;

GoldShopLibrary.Products = modLibraryManager.new();

function GoldShopLibrary.Products:GetProduct(id)
	for productId, productData in pairs(self.Library) do
		if productData.Product and productData.Product.Id == id then
			return self.Library[productId];
		end
	end
	return;
end

--[[
	849095628 = Portable Workbench


	-- MARK: Trader Tag Notes
	Trader={
		Buy=true;  -- Buy from Npc
		Sell=true; -- Sell to Npc
	};
--]]

GoldShopLibrary.Products:Add{
	Id="premium";
	Icon="http://www.roblox.com/asset/?id=4733624021";
	TitleImage="http://www.roblox.com/asset/?id=4733641764";
	TitleText="Premium Member";
	Desc="• Unlock 10 extra inventory space!\n• Premium Member Missions!\n• Get 100% instead of 90% of Perks back when deconstructing mods!";
	Product={
		Type="GamePass";
		Id=2649294;
	};
};

GoldShopLibrary.Products:Add{
	Id="portableWorkbench";
	Icon="http://www.roblox.com/asset/?id=4733624668";
	TitleImage="http://www.roblox.com/asset/?id=4733714983";
	TitleText="Portable Workbench";
	Desc="• Acquire the skill to upgrade your weapon anywhere at anytime!\n• Just press [N] to use your Portable Workbench skill and build, upgrade or customize your items anywhere.\n• No need to rely on a safehouse workbench anymore!";
	Product={
		Type="GamePass";
		Id=2517190;
	};
};

GoldShopLibrary.Products:Add{
	Id="vipTraveler";
	Icon="http://www.roblox.com/asset/?id=6875497046";
	TitleImage="http://www.roblox.com/asset/?id=6875508811";
	TitleText="VIP Traveler";
	Desc="• Become the R.A.T. express patron!\n• Fast traveling with the GPS is now 75% cheaper!.\n• Combined with Premium fast traveling is completely free!";
	Product={
		Type="GamePass";
		Id=18321499;
	};
};

--== Perk Shop;
GoldShopLibrary.Products:Add{
	Id="perks1";
	Icon="http://www.roblox.com/asset/?id=4735824768";
	TitleText="10 Perks";
	Desc="Purchase 10 Perks for 20 Robux.";
	Product={
		Type="Product";
		Id=21015064;
		Perks=10;
	};
};

GoldShopLibrary.Products:Add{
	Id="perks2";
	Icon="http://www.roblox.com/asset/?id=4735825806";
	TitleText="25 Perks + 5 Bonus";
	Desc="Purchase 25 Perks with 55 Robux and get +5 Perks bonus.";
	Product={
		Type="Product";
		Id=21015077;
		Perks=30;
	};
--	LimitedLabel = "NOW 50 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="perks3";
	Icon="http://www.roblox.com/asset/?id=4735826247";
	TitleText="50 Perks + 10 Bonus";
	Desc="Purchase 50 Perks with 110 Robux and get +10 Perks bonus!";
	Product={
		Type="Product";
		Id=21015087;
		Perks=60;
	};
--	LimitedLabel = "NOW 95 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="perks4";
	Icon="http://www.roblox.com/asset/?id=4735827642";
	TitleText="100 Perks + 20 Bonus";
	Desc="Purchase 100 Perks with 210 Robux and get +20 Perks bonus!";
	Product={
		Type="Product";
		Id=21015096;
		Perks=120;
	};
--	LimitedLabel = "NOW 180 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="perks5";
	Icon="http://www.roblox.com/asset/?id=4735828313";
	TitleText="250 Perks + 50 Bonus";
	Desc="Purchase 250 Perks with 520 Robux and get +50 Perks bonus!";
	Product={
		Type="Product";
		Id=37081836;
		Perks=300;
	};
--	LimitedLabel = "NOW 440 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="perks6";
	Icon="http://www.roblox.com/asset/?id=4735829896";
	TitleText="500 Perks + 110 Bonus";
	Desc="Purchase 500 Perks with 960 Robux and get +110 Perks bonus!";
	Product={
		Type="Product";
		Id=37081860;
		Perks=610;
	};
--	LimitedLabel = "NOW 770 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="perks7";
	Icon="http://www.roblox.com/asset/?id=4735830881";
	TitleText="1'000 Perks + 230 Bonus";
	Desc="Purchase 1'000 Perks with 1'920 Robux and get +230 Perks bonus!";
	Product={
		Type="Product";
		Id=37081880;
		Perks=1230;
	};
--	LimitedLabel = "NOW 1530 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="perks8";
	Icon="http://www.roblox.com/asset/?id=4735831191";
	TitleText="2'000 Perks + 480 Bonus";
	Desc="Purchase 2'000 Perks with 3'800 Robux and get +480 Perks bonus!!";
	Product={
		Type="Product";
		Id=37081905;
		Perks=2480;
	};
--	LimitedLabel = "NOW 3040 ROBUX!!";
};

--== Perk Shop;

--== Gold Shop;
GoldShopLibrary.Products:Add{
	Id="250gold";
	Icon="http://www.roblox.com/asset/?id=4734462820";
	TitleText="250 Gold";
	Desc="Purchase 250 Gold for 20 Robux.";
	Product={
		Type="Product";
		Id=963027023;
		Gold=250;
	};
};

GoldShopLibrary.Products:Add{
	Id="500gold";
	Icon="http://www.roblox.com/asset/?id=4734610249";
	TitleText="500 Gold + 125 Bonus";
	Desc="Purchase 500 Gold with 40 Robux and get +125 Gold bonus!";
	Product={
		Type="Product";
		Id=963027164;
		Gold=625;
	};
--	LimitedLabel = "NOW 35 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="1000gold";
	Icon="http://www.roblox.com/asset/?id=4734614398";
	TitleText="1'000 Gold + 250 Bonus";
	Desc="Purchase 1'000 Gold with 80 Robux and get +250 Gold bonus!";
	Product={
		Type="Product";
		Id=963027181;
		Gold=1250;
	};
--	LimitedLabel = "NOW 70 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="5000gold";
	Icon="http://www.roblox.com/asset/?id=4734617273";
	TitleText="5'000 Gold + 1'250 Bonus";
	Desc="Purchase 5'000 Gold with 400 Robux and get +1'250 Gold bonus!";
	Product={
		Type="Product";
		Id=963027208;
		Gold=6250;
	};
--	LimitedLabel = "NOW 340 ROBUX!";
};

GoldShopLibrary.Products:Add{
	Id="10000gold";
	Icon="http://www.roblox.com/asset/?id=4734642242";
	TitleText="10'000 Gold + 2'500 Bonus";
	Desc="Purchase 10'000 Gold with 800 Robux and get +2'500 Gold bonus!!";
	Product={
		Type="Product";
		Id=963027227;
		Gold=12500;
	};
--	LimitedLabel = "NOW 640 ROBUX!!";
};


--== Community Maps;
GoldShopLibrary.Products:Add{
	Id="communitywaysidemap";
	Icon="http://www.roblox.com/asset/?id=11054069128";
	TitleText="Way Side Map";
	Desc="<b>Way Side</b>, a survival map by <b>ChoppyGraph</b>, is an overrun hospital that was used to house and evacuate survivors.<br/><br/>By purchasing this, you are directly supporting <b>ChoppyGraph</b>. This item can only be purchased once and nontradable.";
	Product={
		Type="ThirdParty";
		Id=88822531;
		ProductInfoType=Enum.InfoType.GamePass;
		ItemId="communitywaysidemap";
		CreatorId=86976526;
	};
};

GoldShopLibrary.Products:Add{
	Id="communityfissionbaymap";
	Icon="http://www.roblox.com/asset/?id=14247432855";
	TitleText="Fission Bay Map";
	Desc="<b>Fission Bay</b>, a survival map by <b>Omega_913</b>. Survive hazards and zombies on an abandoned offshore port, surrounded by the cruel and contaminated ocean... let's hope luck is on your side.<br/><br/>By purchasing this, you are directly supporting <b>Omega_913</b>. This item can only be purchased once and nontradable.";
	Product={
		Type="ThirdParty";
		Id=134914087;
		ProductInfoType=Enum.InfoType.GamePass;
		ItemId="communityfissionbaymap";
		CreatorId=99496471;
	};
};

GoldShopLibrary.Products:Add{
	Id="communityrooftopmap";
	Icon="http://www.roblox.com/asset/?id=11054069128";
	TitleText="Rooftops Map";
	Desc="<b>Rooftops</b>, a survival map by <b>Omega_913</b>. Once a proud, bustling structure, now abandoned, imprisoning hulking horrors that we once call humans. Ready your weapons and steel yourselves, it's time to reclaim the rooftops!<br/><br/>By purchasing this, you are directly supporting <b>Omega_913</b>. This item can only be purchased once and nontradable.";
	Product={
		Type="ThirdParty";
		Id=244342317;
		ProductInfoType=Enum.InfoType.GamePass;
		ItemId="communityrooftopmap";
		CreatorId=99496471;
	};
};



--== Gold Shop;

--== Equipment Appearance;
GoldShopLibrary.Products:Add{
	Id="colorlively";
	Icon="";
	TitleText="Lively Colors Pack";
	Desc="Make your equipment feel more lively with this color pack, a more intense version of the dull color pack.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="colorlively";
		PackType="Colors";
		PackId="Lively";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skinstreetart";
	Icon="";
	TitleText="StreetArts Pack";
	Desc="Customize your weapon with Wrighton Dale's wacky street arts and graffiti.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skinstreetart";
		PackType="Skins";
		PackId="StreetArt";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skinwireframe";
	Icon="";
	TitleText="Wireframe Pack";
	Desc="Flash up your tools with a little bit of geometric wireframe pattern.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skinwireframe";
		PackType="Skins";
		PackId="Wireframe";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skinwraps";
	Icon="";
	TitleText="Wraps Pack";
	Desc="Add a bit of fabric wrapping to your stock and handles with this wraps pack.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skinwraps";
		PackType="Skins";
		PackId="Wraps";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="colorarctic";
	Icon="";
	TitleText="Arctic Colors Pack";
	Desc="Color your weapons to blend in with the artic environments.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="colorarctic";
		PackType="Colors";
		PackId="Arctic";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="colorhellsfire";
	Icon="";
	TitleText="Hellsfire Colors Pack";
	Desc="Dip your weapons deep down to the depths of hell and back with these new hellsfire colors.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="colorhellsfire";
		PackType="Colors";
		PackId="Hellsfire";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="colorturquoiseshades";
	Icon="";
	TitleText="Turquoise Shades Colors Pack";
	Desc="The gemstone shades of turquoise, now applicable to your weapons.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="colorturquoiseshades";
		PackType="Colors";
		PackId="TurquoiseShades";
		ShowcaseType="EquipmentSkins";
	};

	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="colorsunset";
	Icon="";
	TitleText="Sunset Colors Pack";
	Desc="Shades of the sun setting and the shades of dusk.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="colorsunset";
		PackType="Colors";
		PackId="Sunset";
		ShowcaseType="EquipmentSkins";
	};

	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="colorabyss";
	Icon="";
	TitleText="Abyss Colors Pack";
	Desc="The bottomless extends to the profound depths of the unknown.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="colorabyss";
		PackType="Colors";
		PackId="Abyss";
		ShowcaseType="EquipmentSkins";
	};

	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skinscaleplating";
	Icon="";
	TitleText="Scale Plating Pack";
	Desc="Reinforce your weapons with some scale plating.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skinscaleplating";
		PackType="Skins";
		PackId="ScalePlating";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skincarbonfiber";
	Icon="";
	TitleText="Carbon Fiber Pack";
	Desc="Coat your weapons with carbon fiber to protect it from wear.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skincarbonfiber";
		PackType="Skins";
		PackId="CarbonFiber";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skinhexatiles";
	Icon="";
	TitleText="Hexatiles Pack";
	Desc="Spice up your weapons with a hexagonal indent tiling.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skinhexatiles";
		PackType="Skins";
		PackId="Hexatiles";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="skinice";
	Icon="";
	TitleText="Ice Skin Pack";
	Desc="Sharpen your weapons' look with some ice crystals.";
	Product={
		Type="Gold";
		Price=200;
		ItemId="skinice";
		PackType="Skins";
		PackId="Ice";
		ShowcaseType="EquipmentSkins";
	};
	
	Trader={Buy=false; Sell=false;};
};

--== MARK: Skin Perms
GoldShopLibrary.Products:Add{
	Id="skinpolaris";
	Icon="";
	TitleText="Polaris Skin Perm";
	Desc="Apply on any weapon a hue shifting start pattern.";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="skinpolaris";
		ShowcaseType="SkinPerm";
		New=true;
	};
	OptInNewCustomizationMenu=true;
	
	Trader={Buy=false; Sell=false;};
};

--== Equipment Appearance;
--== Locked Items;
GoldShopLibrary.Products:Add{
	Id="pyroeverlastmod";
	Icon="";
	TitleText="Pyrotechnic Everlast Mod";
	Desc="Increase flame's burning duration by 31 seconds while reducing ammo capacity by 31 x 2.";
	Product={
		Type="Gold";
		Price=1950;
		ItemId="pyroeverlastmod";
	};
};

GoldShopLibrary.Products:Add{
	Id="sniperskullcrackmod";
	Icon="";
	TitleText="Sniper Skullcracker Mod";
	Desc="Increase headshot multiplier of sniper rifles up to 95%, the mod can only be found once in the mall's secrets.";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="sniperskullcrackmod";
	};
};

GoldShopLibrary.Products:Add{
	Id="hmgrapidfiremod";
	Icon="";
	TitleText="Heavy Machine Gun Rapidfire Mod";
	Desc="Increases rate of fire the longer you hold down primary fire.";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="hmgrapidfiremod";
	};
};

GoldShopLibrary.Products:Add{
	Id="advmedkit";
	Icon="";
	TitleText="Advance Medkit";
	Desc="Advance Medkit will heal you for 75 health in 4.5 seconds.";
	Product={
		Type="Gold";
		Price=100;
		ItemId="advmedkit";
	};
	
	Trader={Buy=true; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="nekronmask";
	Icon="";
	TitleText="Nekron Mask";
	Desc="Once you put it on, the mask will start consuming itself and some zombies will start looking like you..";
	Product={
		Type="Gold";
		Price=990;
		ItemId="nekronmask";
	};
};

GoldShopLibrary.Products:Add{
	Id="dufflebag";
	Icon="";
	TitleText="Dufflebag";
	Desc="Portable storage with a maximum of 15 slots.";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="dufflebag";
	};
};

GoldShopLibrary.Products:Add{
	Id="militaryboots";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="militaryboots";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="sledgehammer";
	Icon="";
	TitleText="Sledgehammer";
	Desc="A construction grade sledgehammer. Base Damage: 800, Attack Speed: 1s";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="sledgehammer";
	};
};

GoldShopLibrary.Products:Add{
	Id="energydrink";
	Product={
		Type="Gold";
		Price=250;
		ItemId="energydrink";
	};
	
	Trader={Buy=true; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="healthmod";
	Product={
		Type="Gold";
		Price=1950;
		ItemId="healthmod";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="armorpointsmod";
	Product={
		Type="Gold";
		Price=1950;
		ItemId="armorpointsmod";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="thornmod";
	Product={
		Type="Gold";
		Price=1950;
		ItemId="thornmod";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="barbedwooden";
	Product={
		Type="Gold";
		Price=490;
		ItemId="barbedwooden";
	};
};

GoldShopLibrary.Products:Add{
	Id="boombox";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="boombox";
	};
};

GoldShopLibrary.Products:Add{
	Id="disguisekit";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="disguisekit";
	};
	
	Trader={Buy=true; Sell=false;};
};


GoldShopLibrary.Products:Add{
	Id="minigun";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="minigun";
	};
};

GoldShopLibrary.Products:Add{
	Id="grenadelauncher";
	Product={
		Type="Gold";
		Price=8950;
		ItemId="grenadelauncher";
	};
};

GoldShopLibrary.Products:Add{
	Id="voodoodoll";
	Product={
		Type="Gold";
		Price=1950;
		ItemId="voodoodoll";
	};
};

GoldShopLibrary.Products:Add{
	Id="flute";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="flute";
	};
};

GoldShopLibrary.Products:Add{
	Id="guitar";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="guitar";
	};
	
};

GoldShopLibrary.Products:Add{
	Id="keytar";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="keytar";
	};

};

GoldShopLibrary.Products:Add{
	Id="nvg";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="nvg";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="gasmask";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="gasmask";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="fireworks";
	Product={
		Type="Gold";
		Price=50;
		ItemId="fireworks";
	};
	
	Trader={Buy=true; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="entityleash";
	Product={
		Type="Gold";
		Price=2800;
		ItemId="entityleash";
	};
};

GoldShopLibrary.Products:Add{
	Id="tophat";
	Product={
		Type="Gold";
		Price=8950;
		ItemId="tophat";
	};
	Trader={Buy=true; Sell=true;};
};

--== Skins

GoldShopLibrary.Products:Add{
	Id="dufflebagstreetart";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="dufflebagstreetart";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="greytshirtcamo";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="greytshirtcamo";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="leatherglovesred";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="leatherglovesred";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="prisonshirtblue";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="prisonshirtblue";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="prisonpantsblue";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="prisonpantsblue";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="dufflebagvintage";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="dufflebagvintage";
	};
	
	Trader={Buy=true; Sell=true;};
};


GoldShopLibrary.Products:Add{
	Id="dufflebagarticscape";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="dufflebagarticscape";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="plankarmormaple";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="plankarmormaple";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="plankarmorash";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="plankarmorash";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="gasmaskwhite";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="gasmaskwhite";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="gasmaskblue";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="gasmaskblue";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="gasmaskyellow";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="gasmaskyellow";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="gasmaskunionjack";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="gasmaskunionjack";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="scraparmorcopper";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="scraparmorcopper";
	};
	
	Trader={Buy=true; Sell=true;};
};

--== Prizes;

GoldShopLibrary.Products:Add{
	Id="divinggogglesyellow";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="divinggogglesyellow";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="disguisekitwhite";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="disguisekitwhite";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="militarybootsforest";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="militarybootsforest";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="watchyellow";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="watchyellow";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="armwrapsrat";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="armwrapsrat";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="inflatablebuoyrat";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="inflatablebuoyrat";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="brownbeltwhite";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="brownbeltwhite";
	};

	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

--== unlockables
GoldShopLibrary.Products:Add{
	Id="tophatgold";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="tophatgold";
	};
	
	Trader={Buy=true; Sell=true;};
	NotForSale=true;
};

GoldShopLibrary.Products:Add{
	Id="scraparmorbiox";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="scraparmorbiox";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="clownmaskus";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="clownmaskus";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="cultistkey1";
	Product={
		Type="Gold";
		Price=20;
		ItemId="cultistkey1";
	};
};

GoldShopLibrary.Products:Add{
	Id="survivorsbackpack";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="survivorsbackpack";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="dufflebagfirstaidgreen";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="dufflebagfirstaidgreen";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="balaclava";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="balaclava";
	};
	
	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="poster";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="poster";
	};
	
	Trader={Buy=false; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="annihilationsoda";
	Product={
		Type="Gold";
		Price=250;
		ItemId="annihilationsoda";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="fotlcardgame";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="fotlcardgame";
	};

	Trader={Buy=false; Sell=false;};
};


--== Summons
GoldShopLibrary.Products:Add{
	Id="zricerahorn";
	Product={
		Type="Gold";
		Price=250;
		ItemId="zricerahorn";
	};

	Trader={Buy=false; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="vexling";
	Product={
		Type="Gold";
		Price=250;
		ItemId="vexling";
	};

	Trader={Buy=false; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="nekronparticulatecache";
	Product={
		Type="Gold";
		Price=250;
		ItemId="nekronparticulatecache";
	};

	Trader={Buy=false; Sell=true;};
};


--== Resource Packages

GoldShopLibrary.Products:Add{
	Id="metalpackage";
	Product={
		Type="Gold";
		Price=500;
		ItemId="metalpackage";
	};

	Trader={Buy=false; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="glasspackage";
	Product={
		Type="Gold";
		Price=500;
		ItemId="glasspackage";
	};

	Trader={Buy=false; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="woodpackage";
	Product={
		Type="Gold";
		Price=500;
		ItemId="woodpackage";
	};

	Trader={Buy=false; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="clothpackage";
	Product={
		Type="Gold";
		Price=500;
		ItemId="clothpackage";
	};

	Trader={Buy=false; Sell=true;};
};

--== SkinPerms

GoldShopLibrary.Products:Add{
	Id="arelshiftcrossantique";
	Product={
		Type="Gold";
		Price=1490;
		ItemId="arelshiftcrossantique";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="desolatorheavytoygun";
	Product={
		Type="Gold";
		Price=1490;
		ItemId="desolatorheavytoygun";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="czevo3asiimov";
	Product={
		Type="Gold";
		Price=1490;
		ItemId="czevo3asiimov";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="rusty48blaze";
	Product={
		Type="Gold";
		Price=1490;
		ItemId="rusty48blaze";
	};

	Trader={Buy=true; Sell=true;};
};

--== NPC TRADERS

GoldShopLibrary.Products:Add{
	Id="czevo3bp";
	Product={
		Type="Gold";
		Price=400;
		ItemId="czevo3bp";
	};

	IgnoreScan=true;
	Trader={Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="desolatorheavybp";
	Product={
		Type="Gold";
		Price=400;
		ItemId="desolatorheavybp";
	};

	IgnoreScan=true;
	Trader={Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="chainsawbp";
	Product={
		Type="Gold";
		Price=400;
		ItemId="chainsawbp";
	};

	IgnoreScan=true;
	Trader={Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="sr308bp";
	Product={
		Type="Gold";
		Price=400;
		ItemId="sr308bp";
	};

	IgnoreScan=true;
	Trader={Sell=true;};
};

--== NPC TRADERS

--== Limited Items;
GoldShopLibrary.Products:Add{
	Id="rusty48bp";
	Product={
		Type="Gold";
		Price=9990;
		ItemId="rusty48bp";
	};
	LimitedId="gs_rusty48bp";

	Trader={Sell=false;};
};
GoldShopLibrary.Products:Add{
	Id="rusty48parts";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="rusty48parts";
	};
	Amount=3;
	LimitedId="gs_rusty48parts";

	Trader={Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="divinggoggles";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="divinggoggles";
	};
	LimitedId="gs_divinggoggles";

	Trader={Sell=false;};
};
GoldShopLibrary.Products:Add{
	Id="divingfins";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="divingfins";
	};
	LimitedId="gs_divingfins";

	Trader={Sell=false;};
};
GoldShopLibrary.Products:Add{
	Id="divingsuit";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="divingsuit";
	};
	LimitedId="gs_divingsuit";

	Trader={Sell=false;};
};
GoldShopLibrary.Products:Add{
	Id="inflatablebuoy";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="inflatablebuoy";
	};
	LimitedId="gs_inflatablebuoy";

	Trader={Sell=false;};
};


GoldShopLibrary.Products:Add{
	Id="clothbagmask";
	Product={
		Type="Gold";
		Price=2950;
		ItemId="clothbagmask";
	};
	LimitedId="gs_clothbagmask";

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="rocketmanmod";
	Icon="";
	TitleText="Rocketman Mod";
	Desc="While player is in the air, reload time is reduced to zero. Compatiable with Rocket tools such as AT4 Rocket Launcher.";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="rocketmanmod";
	};
	LimitedId="gs_rocketmanmod";

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="survivorsoutpostunlockpapers";
	Product={
		Type="Gold";
		Price=24000;
		ItemId="survivorsoutpostunlockpapers";
	};
	LimitedId="gs_survivorsoutpostunlockpapers";

	Trader={Buy=true; Sell=false;};
};

GoldShopLibrary.Products:Add{
	Id="tomeoftweaks";
	Product={
		Type="Gold";
		Price=400;
		ItemId="tomeoftweaks";
	};
	LimitedId="gs_tomeoftweaks";

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="portableautoturret";
	Product={
		Type="Gold";
		Price=24000;
		ItemId="portableautoturret";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="ticksnaretrapbp";
	Product={
		Type="Gold";
		Price=1000;
		ItemId="ticksnaretrapbp";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="pacifistamuletmod";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="pacifistamuletmod";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="warmongerscalesmod";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="warmongerscalesmod";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="mendingmod";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="mendingmod";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="flinchcushioning";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="flinchcushioning";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="ziphoningserum";
	Product={
		Type="Gold";
		Price=490;
		ItemId="ziphoningserum";
	};
	LimitedId="gs_ziphoningserum";

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="nekrosampmod";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="nekrosampmod";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="abandonedbunkermap";
	Product={
		Type="Gold";
		Price=90;
		ItemId="abandonedbunkermap";
		Desc="When purchased, you will receive an abandoned bunker map with a random seed.";
	};
	LimitedId="gs_abandonedbunkermap";

	--Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="engineersplanner";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="engineersplanner";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="tirearmor";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="tirearmor";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="bluntknockoutmod";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="bluntknockoutmod";
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="apron";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="apron";
		New=true;
	};

	Trader={Buy=true; Sell=true;};
};

GoldShopLibrary.Products:Add{
	Id="boomerang";
	Product={
		Type="Gold";
		Price=4990;
		ItemId="boomerang";
		New=true;
		Desc="\n\n\n<b>[Early Access]</b>  Will be obtainable from drops in the future.";
	};
};

--=== CONTENT PAGES

GoldShopLibrary.Pages = {
	FrontPage = {
		{
			Type="Page";
			Id="GoldPage";
			Icon="http://www.roblox.com/asset/?id=4733624290";
			TitleImage="http://www.roblox.com/asset/?id=4733729770";
			Desc="• The currency of the apocalypse!\n• Used among traders. People can trade gold with each other.\n• Use to purchase special items!";
		};
		{
			Type="Page";
			Id="PerksPage";
			Icon="http://www.roblox.com/asset/?id=4733789390";
			TitleImage="http://www.roblox.com/asset/?id=4733790658";
			Desc="• If it can be upgraded, you will need it!\n• Used for upgrading your weapon and tools.\n• Used for customizing your character when armor is implemented!";
		};
		{
			Type="Page";
			Id="PassPage";
			Icon="http://www.roblox.com/asset/?id=4733624021";
			TitleImage="rbxassetid://16501116262";
			Desc="• Permanent upgrades to your gameplay experience!";
		};
		{
			Type="Page";
			Id="CommunityMaps";
			Icon="http://www.roblox.com/asset/?id=10037182552";
			TitleImage="http://www.roblox.com/asset/?id=11055428206";
			Desc="• Community Made Maps with different gamemodes!\n• Support them by purchasing their maps which supports the game!";
		};
		{
			Type="Page";
			Id="LockedItemsPage";
			Icon="rbxassetid://16402082812";
			TitleImage="http://www.roblox.com/asset/?id=5034478392";
			Desc="• These are special items which are either not yet released or rare to obtain!\n• Be the first to acquire some of these special items from the Gold Shop.";
		};

		{
			Type="Page";
			Id="LimitedPage";
			Icon="http://www.roblox.com/asset/?id=1541091147";
			TitleImage="http://www.roblox.com/asset/?id=11134900392";
			Desc="• Want to spend your hard earned gold?\n• Here are some limited stocked items, they are obtainable but if you want them instantly, it comes at a price.";
			LoadLimited=true;
		};
		
	};
	
	GoldPage = {
		{Type="Product"; Id="250gold"};
		{Type="Product"; Id="500gold"};
		{Type="Product"; Id="1000gold"};
		{Type="Product"; Id="5000gold"};
		{Type="Product"; Id="10000gold"};
	};
	
	PerksPage = {
		{Type="Product"; Id="perks1"};
		{Type="Product"; Id="perks2"};
		{Type="Product"; Id="perks3"};
		{Type="Product"; Id="perks4"};
		{Type="Product"; Id="perks5"};
		{Type="Product"; Id="perks6"};
		{Type="Product"; Id="perks7"};
		{Type="Product"; Id="perks8"};
	};
	
	PassPage = {
		{Type="Product"; Id="premium";};
		{Type="Product"; Id="portableWorkbench";};
		{Type="Product"; Id="vipTraveler";};
	};
	
	CommunityMaps = {
		{Type="Product"; Id="communityrooftopmap"};
		{Type="Product"; Id="communityfissionbaymap"};
		{Type="Product"; Id="communitywaysidemap"};
	};
	
	LockedItemsPage = {
		{
			Type="Page";
			Id="NewItems";
			Icon="rbxassetid://16402082812";
			TitleText="New Items";
			Desc="• Newly added Items!";
			New=true;
		};
		{
			Type="Page";
			Id="FunItems";
			Icon="http://www.roblox.com/asset/?id=5627435285";
			TitleText="Fun Items";
			Desc="• Fun tools and consumables.";
		};
		{
			Type="Page";
			Id="SummonsItems";
			Icon="http://www.roblox.com/asset/?id=11154552175";
			TitleText="Summons";
			Desc="• Items to summon bosses.";
		};
		{
			Type="Page";
			Id="WeaponSkins";
			Icon="rbxassetid://13768313905";
			TitleText="Weapon Skins";
			Desc="• Premade skins that can be applied to your tools and weapons and still be customizable!";
		};
		{
			Type="Page";
			Id="ClothingSkins";
			Icon="rbxassetid://6660922252";
			TitleText="Clothing Skins";
			Desc="• Special skin set for your clothing!";
		};
		{
			Type="Page";
			Id="CustomizationsPage";
			Icon="http://www.roblox.com/asset/?id=5065159425";
			TitleText="Customizations";
			Desc="• Colors, skins pack and skin permanents for customizing your items even more!";
		};
	};
	
	NewItems = { --Products with New == true
	};
	
	FunItems = {
		{Type="Product"; Id="keytar"};
		{Type="Product"; Id="annihilationsoda"};
		{Type="Product"; Id="energydrink"};
		{Type="Product"; Id="guitar"};
		{Type="Product"; Id="flute"};
		{Type="Product"; Id="nekronmask"};
		{Type="Product"; Id="fotlcardgame"};
		{Type="Product"; Id="poster"};
	};
	
	SummonsItems = {
		{Type="Product"; Id="zricerahorn"};
		{Type="Product"; Id="vexling"};
		{Type="Product"; Id="nekronparticulatecache"};
	};
	
	WeaponSkins = {
		{Type="Product"; Id="arelshiftcrossantique"};
		{Type="Product"; Id="desolatorheavytoygun"};
		{Type="Product"; Id="czevo3asiimov"};
		{Type="Product"; Id="rusty48blaze"};
	};
	
	CustomizationsPage = {
		{Type="Product"; Id="skinpolaris";};
		{Type="Product"; Id="skinice"};
		{Type="Product"; Id="skinhexatiles"};
		{Type="Product"; Id="skincarbonfiber"};
		{Type="Product"; Id="colorlively"};
		{Type="Product"; Id="colorarctic"};
		{Type="Product"; Id="skinstreetart"};
		{Type="Product"; Id="skinwireframe"};
		{Type="Product"; Id="skinwraps"};
		{Type="Product"; Id="colorhellsfire"};
		{Type="Product"; Id="skinscaleplating"};
		{Type="Product"; Id="colorturquoiseshades"};
		{Type="Product"; Id="colorsunset"};
		{Type="Product"; Id="colorabyss"};
	};
	
	ClothingSkins = {
		{Type="Product"; Id="greytshirtcamo"};
		
		{Type="Product"; Id="dufflebagstreetart"};
		{Type="Product"; Id="dufflebagvintage"};
		{Type="Product"; Id="dufflebagarticscape"};
		
		{Type="Product"; Id="leatherglovesred"};
		
		{Type="Product"; Id="prisonshirtblue"};
		{Type="Product"; Id="prisonpantsblue"};
		
		{Type="Product"; Id="plankarmormaple"};
		{Type="Product"; Id="plankarmorash"};
		
		{Type="Product"; Id="gasmaskwhite"};
		{Type="Product"; Id="gasmaskblue"};
		{Type="Product"; Id="gasmaskyellow"};
		{Type="Product"; Id="gasmaskunionjack"};
		
		{Type="Product"; Id="scraparmorcopper"};
		{Type="Product"; Id="scraparmorbiox"};
		{Type="Product"; Id="clownmaskus"};
	};
	
	SearchItems = {
		{Type="Product"; Id="tophat"};
	};


	LimitedPage = {
		--{
		--	Type="Page";
		--	Id="DivingSet";
		--	Icon="http://www.roblox.com/asset/?id=10342826622";
		--	TitleText="Diving Set";
		--	Desc="• Full diving outfit.";
		--};
		{Type="Product"; Id="ziphoningserum"};
		{Type="Product"; Id="abandonedbunkermap"};
	};
	--DivingSet = {
	--	{Type="Product"; Id="divinggoggles"};
	--	{Type="Product"; Id="divingfins"};
	--	{Type="Product"; Id="divingsuit"};
	--	{Type="Product"; Id="inflatablebuoy"};
	--};
};

for itemId, lib in pairs(GoldShopLibrary.Products:GetAll()) do
	if lib.Product and lib.Product.New == true then
		table.insert(GoldShopLibrary.Pages.NewItems, {Type="Product"; Id=itemId});
	end
end

return GoldShopLibrary;