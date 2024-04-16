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

		local accessoryData = {};
		clothingPackage.AccessoryData = accessoryData;

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

				UniversalVanity = clothingPackage.UniversalVanity;
				HideHands = clothingPackage.HideHands;
				HideFacewear = clothingPackage.HideFacewear;
			};
			
			if package:IsA("Accessory") then
				table.insert(clothingPackage.Accessories, package);
				accessoryData[variantId] = packageInfo;

			else
				local accessories = package:GetChildren();
				packageInfo.Accessories = {};

				for a=1, #accessories do
					local accessory = accessories[a];

					table.insert(packageInfo.Accessories, accessory.Name);
					table.insert(clothingPackage.Accessories, accessory);
				end
				accessoryData[variantId] = packageInfo;
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