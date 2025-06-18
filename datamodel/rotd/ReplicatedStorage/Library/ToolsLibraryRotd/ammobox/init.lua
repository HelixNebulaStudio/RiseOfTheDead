local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="StructureTool";

	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={};

	Configurations={
		WaistRotation = math.rad(0);
		PlaceOffset = CFrame.Angles(0, 0, 0);
		
		BuildDuration = 1;
	};

	Properties={};
};

function toolPackage.BuildStructure(prefab: Model, optionalPacket)
	Debugger.Expire(prefab, 60);

	local newInteractConfig = modInteractables.createInteractable("ResupplyStation", "AmmoBox");
	newInteractConfig:SetAttribute("UseLimit", 3);
	newInteractConfig.Parent = prefab;
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;