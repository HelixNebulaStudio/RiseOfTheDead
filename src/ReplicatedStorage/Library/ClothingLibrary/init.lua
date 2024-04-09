local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);

local RunService = game:GetService("RunService");

local library = modLibraryManager.new();
library.MergeTypes = {
	Add="Add";
	Multiply="Multiply";
	Largest="Largest";
	Smallest="Smallest";
};

library.GroupSettings = {
	ChestGroup = {
		Overlappable = false;
	};
	LegGroup = {
		Overlappable = false;
	};
	BodyGroup = {
		Overlappable = false;
	};
	UnoverlappableGroup = {
		Overlappable = false;
	};
}

library.StatStruct = {
	Warmth={MergeType=library.MergeTypes.Add;};
	AdditionalStamina={MergeType=library.MergeTypes.Add;};
	EquipTimeReduction={MergeType=library.MergeTypes.Multiply;};
	
	UnderwaterVision={MergeType=library.MergeTypes.Largest;};
	
	OxygenDrainReduction={MergeType=library.MergeTypes.Largest;};
	OxygenRecoveryRate={MergeType=library.MergeTypes.Largest;};
	FlinchProtection={MergeType=library.MergeTypes.Largest;};
};

library:SetOnAdd(function(data)
	if data.NewToolLib then return end;
	
	local module = script:FindFirstChild(data.Id);
	if module == nil then
		warn("ClothingLibrary>> Missing "..data.Id.." module script.");
	end

	data.Module=module;
	data.NewToolLib = function()
		return require(data.Module)();
	end;
end)

library:Add{
	Id="brownbelt";
	Name="Brown Belt";
	GroupName="WaistGroup";
};

library:Add{
	Id="bunnymanhead";
	Name="Bunny Man's Head";
	GroupName="HeadGroup";
};

library:Add{
	Id="brownleatherboots";
	Name="Brown Leather Boots";
	GroupName="FootGroup";
};

library:Add{
	Id="gasmask";
	Name="Gas Mask";
	GroupName="HeadGroup";
};

library:Add{
	Id="labcoat";
	Name="Scientist Coat";
	GroupName="ChestGroup";
};

library:Add{
	Id="cowboyhat";
	Name="Mellow Cowboy";
	GroupName="HeadGroup";
};

library:Add{
	Id="nekronmask";
	Name="Nekron Mask";
	GroupName="HeadGroup";
};

library:Add{
	Id="cultisthood";
	Name="Cultist Hood";
	GroupName="HeadGroup";
};

library:Add{
	Id="prisonshirt";
	Name="Prisoner's Shirt";
	GroupName="ChestGroup";
};

library:Add{
	Id="prisonpants";
	Name="Prisoner's Pants";
	GroupName="LegGroup";
};

library:Add{
	Id="onyxhoodie";
	Name="OnyxHound Hoodie";
	GroupName="ChestGroup";
};

library:Add{
	Id="onyxhoodiehood";
	Name="OnyxHound Hoodie Hood";
	GroupName="HeadGroup";
};

--library:Add{
--	Id="militaryboots";
--	Name="Military Boots";
--	GroupName="FootGroup";
--};

library:Add{
	Id="greytshirt";
	Name="Grey Tshirt";
	GroupName="ChestGroup";
}

library:Add{
	Id="plankarmor";
	Name="Plank Armor";
	GroupName="ChestGroup";
}

library:Add{
	Id="disguisekit";
	Name="Disguise Kit";
	GroupName="HeadGroup";
};


library:Add{
	Id="nvg";
	Name="nvg";
	GroupName="HeadGroup";
};

library:Add{
	Id="santahat";
	Name="santahat";
	GroupName="HeadGroup";
};

library:Add{
	Id="greensantahat";
	Name="greensantahat";
	GroupName="HeadGroup";
};

library:Add{
	Id="xmassweater";
	Name="Xmas Sweater";
	GroupName="ChestGroup";
};

library:Add{
	Id="watch";
	Name="watch";
	GroupName="MiscGroup";
};

library:Add{
	Id="strawhat";
	Name="Straw Hat";
	GroupName="HeadGroup";
};

--library:Add{
--	Id="leathergloves";
--	Name="FingerlessLeatherGloves";
--	GroupName="HandGroup";
--};
library:Add{
	Id="zriceraskull";
	Name="ZriceraSkull";
	GroupName="HeadGroup";
};

library:Add{
	Id="scraparmor";
	Name="Scrap Armor";
	GroupName="ChestGroup";
}

library:Add{
	Id="hazmathood";
	Name="hazmathood";
	GroupName="HeadGroup";
};

--library:Add{
--	Id="armwraps";
--	Name="ArmWraps";
--	GroupName="HandGroup";
--};

library:Add{
	Id="vexgloves";
	Name="vexgloves";
	GroupName="HandGroup";
};

library:Add{
	Id="tophat";
	Name="tophat";
	GroupName="HeadGroup";
};

library:Add{
	Id="clownmask";
	Name="clownmask";
	GroupName="HeadGroup";
};

--library:Add{
--	Id="survivorsbackpack";
--	Name="SurvivorsBackpack";
--	GroupName="MiscGroup";
--};


library:Add{
	Id="highvisjacket";
	Name="highvisjacket";
	GroupName="ChestGroup";
};

library:Add{
	Id="balaclava";
	Name="balaclava";
	GroupName="HeadGroup";
};

library:Add{
	Id="divinggoggles";
	Name="divinggoggles";
	GroupName="HeadGroup";
};

library:Add{
	Id="divingfins";
	Name="divingfins";
	GroupName="FootGroup";
};


library:Add{
	Id="divingsuit";
	Name="divingsuit";
	GroupName="BodyGroup";
};

library:Add{
	Id="inflatablebuoy";
	Name="inflatablebuoy";
	GroupName="MiscGroup";
};

library:Add{
	Id="skullmask";
	Name="skullmask";
	GroupName="HeadGroup";
};

library:Add{
	Id="maraudersmask";
	Name="maraudersmask";
	GroupName="HeadGroup";
};

library:Add{
	Id="clothbagmask";
	Name="clothbagmask";
	GroupName="HeadGroup";
};

function library.LoadToolModule(module)
	if module.Name == "ClothingProperties" then return end;
	if not module:IsA("ModuleScript") then return end;

	local itemId = module.Name;

	local clothingPackage = require(module);
	
	if typeof(clothingPackage) == "function" then
		return;
	end
	
	clothingPackage.Id = itemId;
	clothingPackage.Name = clothingPackage.Name or itemId;
	clothingPackage.Module = module;
	clothingPackage.Accessories = {};
	clothingPackage.Varients = {};

	local groupName = clothingPackage.GroupName;
	if RunService:IsServer() then
		local folderCosmetics = game.ServerStorage.PrefabStorage.Cosmetics;
		
		local modAppearanceLibrary = require(game.ReplicatedStorage.Library.AppearanceLibrary);
		if modAppearanceLibrary[groupName] == nil then
			modAppearanceLibrary[groupName] = {};
		end
		
		local accessoryGroup = modAppearanceLibrary[groupName];
		
		local packagesList = module:GetChildren();
		
		for _, package in pairs(packagesList) do
			if package:GetAttribute("PackageVariant") ~= true then continue end;
			
			local variantId = package.Name == "package" and itemId or package.Name;
			
			if variantId ~= itemId then
				table.insert(clothingPackage.Varients, variantId);
			end
			
			local packageInfo = {
				Name=variantId;
				GroupName=groupName;
			};
			
			if package:IsA("Accessory") then
				modAppearanceLibrary[groupName][variantId] = packageInfo;
				table.insert(clothingPackage.Accessories, package);
				
			else
				local accessories = package:GetChildren();
				packageInfo.Accessories = {};

				for a=1, #accessories do
					local accessory = accessories[a];

					table.insert(packageInfo.Accessories, accessory.Name);
					table.insert(clothingPackage.Accessories, accessory);
				end

				modAppearanceLibrary[groupName][variantId] = packageInfo;
				
			end
			
			local groupFolder = folderCosmetics:FindFirstChild(groupName);
			if groupFolder == nil then
				groupFolder = Instance.new("Folder");
				groupFolder.Name = groupName;
				groupFolder.Parent = folderCosmetics
			end

			package.Name = variantId;
			package.Parent = groupFolder;
		end
		

		--local accessoryPackage = module:FindFirstChild("package");
		--if accessoryPackage then
		--	if accessoryPackage:IsA("Folder") then
		--		local accessories = accessoryPackage:GetChildren();
		--		packageInfo.Accessories = {};

		--		for a=1, #accessories do
		--			local accessory = accessories[a];

		--			table.insert(packageInfo.Accessories, accessory.Name);
		--			table.insert(clothingPackage.Accessories, accessory);
		--		end
				
		--		modAppearanceLibrary[groupName][itemId] = packageInfo;

		--	elseif accessoryPackage:IsA("Accessory") then
		--		modAppearanceLibrary[groupName][itemId] = packageInfo;
		--		table.insert(clothingPackage.Accessories, accessoryPackage);
				
		--	end

		--	local folderCosmetics = game.ServerStorage.PrefabStorage.Cosmetics;

		--	local groupFolder = folderCosmetics:FindFirstChild(groupName);
		--	if groupFolder == nil then
		--		groupFolder = Instance.new("Folder");
		--		groupFolder.Name = groupName;
		--		groupFolder.Parent = folderCosmetics
		--	end

		--	accessoryPackage.Name = itemId;
		--	accessoryPackage.Parent = groupFolder;
		--end
	end

	local clothingLib = library:Find(itemId);
	if clothingLib then
		library:Replace(itemId, clothingPackage);
	else
		library:Add(clothingPackage);
	end
end

for _, m in pairs(script:GetChildren()) do
	library.LoadToolModule(m);
end
script.ChildAdded:Connect(library.LoadToolModule);


local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;