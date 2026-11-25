local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modMovementLibrary = shared.require(game.ReplicatedStorage.Library.MovementLibrary);

--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "UnoverlappableGroup";
	
	CtrlMovementId = "Sled";

	Configurations = {
		HasFlinchProtection = true;
	};
	Properties = {};
};

function attirePackage.OnAccesorySpawn(playerClass: PlayerClass, storageItem: StorageItem, newAccessoryPrefabs)
	local accessory = newAccessoryPrefabs and newAccessoryPrefabs[1];
	if typeof(accessory) ~= "Instance" then return end;

	local accessoryHandle = accessory:WaitForChild("Handle");
	local vehicleWearMotor = accessoryHandle:WaitForChild("VehicleWear");

	vehicleWearMotor.Part0 = playerClass.RootPart;
	vehicleWearMotor.Part1 = accessoryHandle;

	local vehicleMovementLib = modMovementLibrary:Find(attirePackage.CtrlMovementId);
	local vehicleAnimationId = vehicleMovementLib and vehicleMovementLib.SlideAnimationId;

	local humanoid: Humanoid = playerClass.Humanoid;
	local animator = humanoid:WaitForChild("Animator") :: Animator;
	
	local conn = animator.AnimationPlayed:Connect(function(animationTrack: AnimationTrack)
		if vehicleAnimationId == nil then return end;
		if animationTrack.Animation.AnimationId ~= vehicleAnimationId then return end;
		
		local accWeld;
		for _, obj in pairs(accessoryHandle:GetChildren()) do
			if obj.Name == "AccessoryWeld" or obj.Name == "AccessoryRigidConstraint" then
				obj:Destroy();
				continue;
			end;
			if not obj:IsA("Weld") then continue end;

			obj.Enabled = false;
			accWeld = obj;
		end
		vehicleWearMotor.Enabled = true;

		animationTrack:GetPropertyChangedSignal("IsPlaying"):Once(function()
			accWeld.Enabled = true;
			vehicleWearMotor.Enabled = false;
		end)
	end)
	accessory.Destroying:Connect(function()
		conn:Disconnect();
		conn = nil;
	end)
end

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("Sledding", {
		SetValues={
			CtrlMovementId = attirePackage.CtrlMovementId;
		};
	});

	return equipmentClass;
end

return attirePackage;
