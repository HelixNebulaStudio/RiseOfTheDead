local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Use={Id=10964648124};
	};
};


function toolPackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.PlaceOffset = CFrame.Angles(0, 0, 0);

	toolLib.Prefab = "ammobox";
	toolLib.BuildDuration = 1;

	function toolLib:OnSpawn(prefab)
		Debugger.Expire(prefab, 60);
		
		local newInteractable = script.Interactable:Clone();
		newInteractable:SetAttribute("UseLimit", 1);
		newInteractable.Parent = prefab;

		local interactData = require(newInteractable);
	end
	
	
	toolLib.__index = toolLib;
	setmetatable(toolLib, handler);
	return toolLib;
end

return toolPackage;