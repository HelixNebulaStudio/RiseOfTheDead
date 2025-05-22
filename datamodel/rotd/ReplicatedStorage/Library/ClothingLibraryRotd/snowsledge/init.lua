local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="UnoverlappableGroup";
	
	VehicleWearAnimationId="rbxassetid://112890221559544";

	Configurations={
		HasFlinchProtection = true;
		UnderwaterVision = 0.06;
	};
	Properties={};
};

function attirePackage.OnAccesorySpawn(classPlayer, storageItem, newAccessoryPrefabs)
	local accessory = newAccessoryPrefabs and newAccessoryPrefabs[1];
	if typeof(accessory) ~= "Instance" then return end;

	local character = classPlayer:GetCharacter();
	
	local accessoryHandle = accessory:WaitForChild("Handle");
	local vehicleWearMotor = accessoryHandle:WaitForChild("VehicleWear");

	vehicleWearMotor.Part0 = classPlayer.RootPart;
	vehicleWearMotor.Part1 = accessoryHandle;

	local humanoid: Humanoid = classPlayer.Humanoid;
	local animator = humanoid:WaitForChild("Animator") :: Animator;
	
	local conn = animator.AnimationPlayed:Connect(function(animationTrack: AnimationTrack)
		if animationTrack.Animation.AnimationId ~= attirePackage.VehicleWearAnimationId then return end;
		
		local accWeld;
		for _, obj in pairs(accessoryHandle:GetChildren()) do
			if not obj:IsA("Weld") then continue end;
			if obj.Name == "AccessoryWeld" then
				obj:Destroy();
				continue;
			end;

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
			VehicleWear="snowsledge";
			VehicleWearAnimationId=attirePackage.VehicleWearAnimationId;
		};
	});

	return equipmentClass;
end

return attirePackage;