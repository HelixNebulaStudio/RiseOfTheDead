local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.PlaceOffset = CFrame.Angles(0, 0, 0);

	Tool.Prefab = "ammobox";
	Tool.BuildDuration = 1;

	function Tool:OnSpawn(prefab)
		Debugger.Expire(prefab, 60);
		
		local newInteractable = script.Interactable:Clone();
		newInteractable:SetAttribute("UseLimit", 3);
		newInteractable.Parent = prefab;

		local interactData = require(newInteractable);
	end
	
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;