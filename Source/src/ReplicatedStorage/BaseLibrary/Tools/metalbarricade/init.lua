local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="StructureTool";

	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={};

	Configurations={
		WaistRotation = math.rad(85);
		PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
		
		BuildDuration = 1;
	};

	Properties={};
};

function toolPackage.OnSpawn(handler, prefab: Model)
	if modConfigurations.ExpireDeployables == true then
		Debugger.Expire(prefab, 300);
	end
	
	modAudio.Play("Repair", prefab.PrimaryPart);
	
	local size = prefab:GetExtentsSize();
	local enemyClip = Instance.new("Part");
	enemyClip.Name = "_enemyClip";
	enemyClip.Anchored = true;
	enemyClip.CanCollide = true;
	enemyClip.Transparency = 1;
	enemyClip.Size = Vector3.new(1, size.Y+2, size.Z+0.2);
	enemyClip.CFrame = prefab:GetPivot() * CFrame.new(-1, 4, 0);
	enemyClip.Parent = workspace.Clips;
	
	prefab.Destroying:Connect(function()
		enemyClip:Destroy();
	end)
	
	task.spawn(function()
		while enemyClip:IsAncestorOf(workspace) do
			task.wait(math.random(10, 30));
			enemyClip.CanCollide = false;
			task.wait(math.random(1,3));
			enemyClip.CanCollide = true;
		end
	end)
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;