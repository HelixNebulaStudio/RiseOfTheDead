local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="StructureTool";

	Animations={
		Core={Id=4493584242;};
		Placing={Id=4493588865};
	};
	Audio={};

	Configurations={
		WaistRotation = math.rad(0);
		PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
		
		BuildDuration = 1;
	};

	Properties={};
};

function toolPackage.OnSpawn(handler, prefab: Model)
	local player = handler.Player;

	modAudio.Play("Repair", prefab.PrimaryPart);
	local humanoid = prefab:WaitForChild("Structure");
	humanoid.Parent = nil;
	
	prefab.Name = player.Name.."'s Snowman";
	local rootPart = prefab:WaitForChild("root");
	rootPart.Name = "HumanoidRootPart";
	
	humanoid.Parent = prefab;
	
	local appearance = player:FindFirstChild("Appearance");
	local head = prefab:FindFirstChild("Head");
	if appearance and head then
		for _, accessory in pairs(appearance:GetChildren()) do
			local attachment = accessory:FindFirstChildWhichIsA("Attachment", true);
			
			if attachment and head:FindFirstChild(attachment.Name) then
				local new = accessory:Clone();
				new.Parent = prefab;
			end
		end
	end
	if head then
		head.CollisionGroup = "Debris";
	end
	
	spawn(function()
		repeat
			humanoid.Health = humanoid.Health -0.2;
			shared.modNpcs.attractNpcs(prefab, 64, function(npcClass: NpcClass)
				local isZombie = npcClass.Humanoid and npcClass.Humanoid.Name == "Zombie";
				local isBasicEnemy = npcClass.Properties and npcClass.Properties.BasicEnemy == true;

				return isZombie and isBasicEnemy;
			end);
		until humanoid.Health <= 0 or not wait(1);
	end)
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;