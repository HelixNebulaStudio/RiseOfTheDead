local Appearance = {};
local thumbnailApi = "http://www.roblox.com/Game/Tools/ThumbnailAsset.ashx?wd=420&ht=420&fmt=png&aid=";
Appearance.EnumStore = {Marketplace=1; Unlockable=2; Developer=3; Free=10;};
Appearance.EnumTier = {
	Tier1="Tier1";
	Tier3="Tier3";
}

Appearance.Tiers = {
	Tier1={
		Color=Color3.fromRGB(50, 50, 50); --Color3.fromRGB(57, 86, 77);
		Image=nil;
	};
	Tier3={
		Color=Color3.fromRGB(101, 59, 169); --Color3.fromRGB(57, 86, 77);
		Image=nil;
	};
}


Appearance.BodyGroup = {
	["divingsuit"]={
		Name="divingsuit";
		AssetId=1744585941;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA"; "LUL"; "LLL"; "RUL"; "RLL";}
	};
}

Appearance.MiscGroup = {
	["SurvivorsBackpack"]={
		Name="SurvivorsBackpack";
		AssetId=1744585941;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
	["dufflebag"]={
		Name="dufflebag";
		AssetId=1744585941;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
	["BackGuitar"]={
		Name="BackGuitar";
		AssetId=1744585941;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
	--["ammopouch"]={
	--	Name="ammopouch";
	--	AssetId=1;
	--	Store=Appearance.EnumStore.Free;
	--	Tier=Appearance.EnumTier.Tier1;
	--	ListOrder=1;
	--};
	["inflatablebuoy"]={
		Name="inflatablebuoy";
		AssetId=1744585941;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
	["watch"]={
		Name="watch";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
}

Appearance.HairGroup = {
	["Black Ponytail"]={
		Name="Black Ponytail";
		AssetId=376527350;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
	["True Blue Hair"]={
		Name="True Blue Hair";
		AssetId=451221329;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=2;
	};
	["Brown Charmer Hair"]={
		Name="Brown Charmer Hair";
		AssetId=376548738;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=3;
	};
	["Lavender Updo"]={
		Name="Lavender Updo";
		AssetId=451220849;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=4;
	};
	["Straight Blond Hair"]={
		Name="Straight Blond Hair";
		AssetId=376526888;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=5;
	};
	["Blond Spiked Hair"]={
		Name="Blond Spiked Hair";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
}

Appearance.HeadGroup = {
	["Blonde Beard"]={
		Name="Blonde Beard";
		AssetId=323418594;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
	["Thick Beard"]={
		Name="Thick Beard";
		AssetId=158066137;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=2;
	};
	["Blue Frames"]={
		Name="Blue Frames";
		AssetId=116778553;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=10;
	};
	["Nerd Glasses"]={
		Name="Nerd Glasses";
		AssetId=11884330;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=12;
	};
	["Eyepatch"]={
		Name="Eyepatch";
		AssetId=74970669;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=12;
	};
	["Italian Ski Cap"]={
		Name="Italian Ski Cap";
		AssetId=1038669;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Snow Leopard Fedora"]={
		Name="Snow Leopard Fedora";
		AssetId=128159229;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Purple Cat Ears Headphones"]={
		Name="Purple Cat Ears Headphones";
		AssetId=244159564;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Buddy Baseball Cap"]={
		Name="Buddy Baseball Cap";
		AssetId=68259961;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["ROBLOX U Beanie"]={
		Name="ROBLOX U Beanie";
		AssetId=173784332;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Shark Knit"]={
		Name="Shark Knit";
		AssetId=100930361;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Soldier's Setup"]={
		Name="Soldier's Setup";
		AssetId=111902585;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Ninja with Pony Tail"]={
		Name="Ninja with Pony Tail";
		AssetId=255794861;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["4th Brigade, 2nd Division"]={
		Name="4th Brigade, 2nd Division";
		AssetId=25701541;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=20;
	};
	["Bunny Man's Head"]={
		Name="Bunny Man's Head";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	["Gas Mask"]={
		Name="Gas Mask";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	["Nekron Mask"]={
		Name="Nekron Mask";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	["Mellow Cowboy"]={
		Name="Mellow Cowboy";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	["Cultist Hood"]={
		Name="Cultist Hood";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
		HideHair=true;
	};
	["OnyxHound Hoodie Hood"]={
		Name="OnyxHound Hoodie Hood";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
		HideHair=true;
	};
	
	["Disguise Kit"]={
		Name="Disguise Kit";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
		HideFacewear=true;
	};

	["nvg"]={
		Name="nvg";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
		HideFacewear=true;
	};
	
	["santahat"]={
		Name="santahat";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};

	["greensantahat"]={
		Name="greensantahat";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};

	["Straw Hat"]={
		Name="Straw Hat";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};

	["ZriceraSkull"]={
		Name="ZriceraSkull";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	
	["hazmathood"]={
		Name="hazmathood";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	
	["tophat"]={
		Name="tophat";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	
	["clownmask"]={
		Name="clownmask";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	
	["balaclava"]={
		Name="balaclava";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};
	
	["divinggoggles"]={
		Name="divinggoggles";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};

	["skullmask"]={
		Name="skullmask";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};

	["maraudersmask"]={
		Name="maraudersmask";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
	};

	["clothbagmask"]={
		Name="clothbagmask";
		AssetId=376524487;
		Store=Appearance.EnumStore.Marketplace;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=6;
		HideHair=true;
	};
};


Appearance.ChestGroup = {
	["White Tucked Tshirt"]={
		Name="White Tucked Tshirt";
		AssetId=1744906234;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA";}
	};
	["Grey Tshirt"]={
		Name="Grey Tshirt";
		AssetId=1744913038;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA";}
	};
	["Green Camo Tshirt"]={
		Name="Green Camo Tshirt";
		AssetId=1745105880;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA";}
	};
	["Robert's Jacket"]={
		Name="Robert's Jacket";
		AssetId=4744979205;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA";}
	};
	["Prisoner's Shirt"]={
		Name="Prisoner's Shirt";
		AssetId=2017492911;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA";}
	};
	["Black Suit"]={
		Name="Black Suit";
		AssetId=4756706792;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA";}
	};
	["Scientist Coat"]={
		Name="Scientist Coat";
		AssetId=4762779943;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA";}
	};
	["OnyxHound Hoodie"]={
		Name="OnyxHound Hoodie";
		AssetId=4770134863;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA";}
	};
	["Plank Armor"]={
		Name="Plank Armor";
		AssetId=4756706792;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT";}
	};
	["Scrap Armor"]={
		Name="Scrap Armor";
		AssetId=4756706792;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT";}
	};

	["Xmas Sweater"]={
		Name="Xmas Sweater";
		AssetId=4770134863;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA";}
	};
	
	["highvisjacket"]={
		Name="highvisjacket";
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		Accessories={"UT"; "LT"; "LUA"; "RUA"; "LLA"; "RLA";}
	}
};

Appearance.ArmGroup = {
	
};

Appearance.HandGroup = {
	["vexgloves"]={
		Name="vexgloves";
		AssetId=4749912501;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"LH"; "RH";};
		HideHands=true;
	};
};

Appearance.WaistGroup = {
	["Brown Belt"]={
		Name="Brown Belt";
		AssetId=1744585941;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
	};
};

Appearance.LegGroup = {
	["Blue Shorts"]={
		Name="Blue Shorts";
		AssetId=1742057082;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"LT"; "LUL"; "RUL";}
	};
	["Pink Shorts"]={
		Name="Pink Shorts";
		AssetId=1742158851;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"LT"; "LUL"; "RUL";}
	};
	["Black Pants"]={
		Name="Black Pants";
		AssetId=4756707135;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"LLL"; "LUL"; "RLL"; "RUL";}
	};
	["White Pants"]={
		Name="White Pants";
		AssetId=4762780173;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"LLL"; "LUL"; "RLL"; "RUL";}
	};
	["Prisoner's Pants"]={
		Name="Prisoner's Pants";
		AssetId=4762780173;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Accessories={"LLL"; "LUL"; "RLL"; "RUL";}
	};
	--["mercskneepads"]={
	--	Name="mercskneepads";
	--	AssetId=4762780173;
	--	Store=Appearance.EnumStore.Free;
	--	Tier=Appearance.EnumTier.Tier1;
	--	ListOrder=1;
	--	Accessories={"LUL"; "RUL";}
	--};
};

Appearance.FootGroup = {
	["Black Shoes"]={
		Name="Black Shoes";
		AssetId=1738802962;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Attachments={
			{Name="LeftFootAttachment"; Orientation=Vector3.new(0, 0, 0); Position=Vector3.new(-0.056, -0.318, 0.158)};
			{Name="RightFootAttachment"; Orientation=Vector3.new(0, 0, 0); Position=Vector3.new(0.056, -0.318, 0.158)};
		};
	};
	["Brown Shoes"]={
		Name="Brown Shoes";
		AssetId=1733157469;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Attachments={
			{Name="LeftFootAttachment"; Orientation=Vector3.new(0, 0, 0); Position=Vector3.new(-0.056, -0.318, 0.158)};
			{Name="RightFootAttachment"; Orientation=Vector3.new(0, 0, 0); Position=Vector3.new(0.056, -0.318, 0.158)};
		};
	};
	["Brown Leather Boots"]={
		Name="Brown Leather Boots";
		AssetId=1733157469;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Attachments={
			{Name="LeftFootAttachment"; PrefabName="Foot"; Orientation=Vector3.new(0, -178, 0); Position=Vector3.new(0.06, -0.374, -0.185)};
			{Name="LeftLowerLegAttachment"; PrefabName="LowerLeg"; Orientation=Vector3.new(0, -178, 0); Position=Vector3.new(0.003, -0.202, -0.011)};
			{Name="RightFootAttachment"; PrefabName="Foot"; Orientation=Vector3.new(0, -178, 0); Position=Vector3.new(-0.06, -0.374, -0.15)};
			{Name="RightLowerLegAttachment"; PrefabName="LowerLeg"; Orientation=Vector3.new(0, -178, 0); Position=Vector3.new(-0.002, -0.202, 0.02)};
		};
	};
	["Military Boots"]={
		Name="Military Boots";
		AssetId=1733157469;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Attachments={
			{Name="LeftFootAttachment"; PrefabName="Foot"; Orientation=Vector3.new(0, 180, 0); Position=Vector3.new(0.058, -0.255, -0.116)};
			{Name="LeftLowerLegAttachment"; PrefabName="LowerLeg"; Orientation=Vector3.new(0, 180, 0); Position=Vector3.new(0, 0.14, -0.019)};
			{Name="RightFootAttachment"; PrefabName="Foot"; Orientation=Vector3.new(0, 180, 0); Position=Vector3.new(-0.052, -0.255, -0.112)};
			{Name="RightLowerLegAttachment"; PrefabName="LowerLeg"; Orientation=Vector3.new(0, 180, 0); Position=Vector3.new(0, 0.14, -0.019)};
		};
	};
	["Oxford Shoes"]={
		Name="Oxford Shoes";
		AssetId=1733157469;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Attachments={
			{Name="LeftFootAttachment"; Orientation=Vector3.new(0, 180, 0); Position=Vector3.new(0.058, -0.382, -0.166)};
			{Name="RightFootAttachment"; Orientation=Vector3.new(0, 180, 0); Position=Vector3.new(-0.058, -0.382, -0.166)};
		};
	};

	["divingfins"]={
		Name="divingfins";
		AssetId=1738802962;
		Store=Appearance.EnumStore.Free;
		Tier=Appearance.EnumTier.Tier1;
		ListOrder=1;
		Attachments={
			{Name="LeftFootAttachment"; Orientation=Vector3.new(0, 0, 0); Position=Vector3.new(-0.05, -0.285, 0.71)};
			{Name="RightFootAttachment"; Orientation=Vector3.new(0, 0, 0); Position=Vector3.new(0.05, -0.285, 0.71)};
		};
	};
	
};

local cosmeticGroups = {
	{Dictionary=Appearance.HairGroup; Name="HairGroup";};
	{Dictionary=Appearance.HeadGroup; Name="HeadGroup";};
	{Dictionary=Appearance.ChestGroup; Name="ChestGroup";};
	{Dictionary=Appearance.ArmGroup; Name="ArmGroup";};
	{Dictionary=Appearance.HandGroup; Name="HandGroup";};
	{Dictionary=Appearance.WaistGroup; Name="WaistGroup";};
	{Dictionary=Appearance.LegGroup; Name="LegGroup";};
	{Dictionary=Appearance.FootGroup; Name="FootGroup";};
};

function Appearance:Get(group, name)
	if name == "DefaultHair" or name == "Hidden" then return end;
	if group and Appearance[group] and Appearance[group][name] then
		return Appearance[group][name], group;
	end
	if name then
		for a=1, #cosmeticGroups do
			if cosmeticGroups[a].Dictionary[name] then
				return cosmeticGroups[a].Dictionary[name], cosmeticGroups[a].Name;
			end
		end
	end
end

--local folderCosmetics, folderModCosmetics;
--if game:GetService("RunService"):IsServer() then
--	folderCosmetics = game.ServerStorage.PrefabStorage.Cosmetics;
--	folderModCosmetics = game.ServerStorage:FindFirstChild("ModPrefabs") and game.ServerStorage.ModPrefabs:FindFirstChild("Cosmetics") or nil;
--end
--if prefabGroup == nil and folderModCosmetics then
--	prefabGroup = folderModCosmetics:FindFirstChild(group) and folderModCosmetics[group]:FindFirstChild(itemId) or nil;
--end

local folderCosmetics;
if game:GetService("RunService"):IsServer() then
	folderCosmetics = game.ServerStorage.PrefabStorage.Cosmetics;
end

function Appearance:GetPrefabGroup(group, itemId)
	local prefabGroup = folderCosmetics:FindFirstChild(group) and folderCosmetics[group]:FindFirstChild(itemId) or nil;

	return prefabGroup;
end

return Appearance;