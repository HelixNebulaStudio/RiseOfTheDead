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

function toolPackage.OnSpawn(handler, prefab: Model)
	Debugger.Expire(prefab, 60);
		
	local newInteractable = script.Interactable:Clone();
	newInteractable:SetAttribute("UseLimit", 3);
	newInteractable.Parent = prefab;

	local interactData = shared.require(newInteractable);
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;