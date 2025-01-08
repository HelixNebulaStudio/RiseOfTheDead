local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="UnoverlappableGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.VehicleWearAnimationId="rbxassetid://112890221559544";

	function toolLib:OnAccesorySpawn(classPlayer, storageItem, newAccessoryPrefabs)
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
			if animationTrack.Animation.AnimationId ~= toolLib.VehicleWearAnimationId then return end;
			
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

	local clothing = modClothingProperties.new(toolLib);

	clothing:RegisterPlayerProperty("Sledding", {
		Visible = false;

		VehicleWear="snowsledge";
		VehicleWearAnimationId=toolLib.VehicleWearAnimationId;
	});

	return clothing;
end

return attirePackage;