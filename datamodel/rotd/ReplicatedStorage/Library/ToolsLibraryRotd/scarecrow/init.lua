local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
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

function toolPackage.BuildStructure(prefab: Model, optionalPacket)
	optionalPacket = optionalPacket or {};

	local player;
	if optionalPacket.CharacterClass and optionalPacket.CharacterClass.ClassName == "PlayerClass" then
		player = optionalPacket.CharacterClass:GetInstance();
	end;
	if player == nil then return end;

	modAudio.Play("Repair", prefab.PrimaryPart);
	
	prefab.Name = `{player.Name}'s Scarecrow`;
	local rootPart = prefab:WaitForChild("root");
	rootPart.Name = "HumanoidRootPart";
	
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
	
	local destructibleConfig = modDestructibles.createDestructible("Scarecrow");
	destructibleConfig.Parent = prefab;
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;