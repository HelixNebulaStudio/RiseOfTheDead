local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local remoteShopService = modRemotesManager:Get("ShopService");
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "UnoverlappableGroup";
	
	StorageId = "portableautoturret";
	StorageIndexEnums = {
		WeaponSlot = 1;
		BatterySlot = 2;
	};

	Configurations = {};
	Properties = {};

	KeyIdControls = {["KeyTogglePat"]={Index=1};};
};

local turretArmPrefab = script:WaitForChild("turretArm");
function attirePackage.OnAccesorySpawn(playerClass: PlayerClass, storageItem: StorageItem, newAccessoryPrefabs)
	local accessory = newAccessoryPrefabs and newAccessoryPrefabs[1];
	if typeof(accessory) ~= "Instance" then return end;
	
	local newArm = turretArmPrefab:Clone();

	local hydraulicAtt = accessory:WaitForChild("Handle"):WaitForChild("HydraulicsRoot");
	local hydraulicConstraint = newArm:WaitForChild("Hydraulics"):WaitForChild("RigidConstraint");
	hydraulicConstraint.Attachment1 = hydraulicAtt;

	local utAtt = accessory:WaitForChild("Handle"):WaitForChild("UpperTorsoAttachment");
	newArm:WaitForChild("LCables"):WaitForChild("RigidConstraint").Attachment1 = utAtt;
	newArm:WaitForChild("LCables2"):WaitForChild("RigidConstraint").Attachment1 = utAtt;
	
	newArm.Parent = accessory;
	
	accessory:WaitForChild("Handle").ChildAdded:Connect(function(surfApp)
		if not surfApp:IsA("SurfaceAppearance") then return end;
		for _, obj in pairs(newArm:GetChildren()) do
			if obj:IsA("BasePart") then
				for _, sf in pairs(obj:GetChildren()) do
					if sf:IsA("SurfaceAppearance") then
						sf:Destroy()
					end
				end

				surfApp:Clone().Parent = obj;
			end
		end
	end)

	task.spawn(function()
		local storage = shared.modStorage.Get(attirePackage.StorageId, playerClass:GetInstance());
		if storage then
			storage:Changed();
		end
	end)
end

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;