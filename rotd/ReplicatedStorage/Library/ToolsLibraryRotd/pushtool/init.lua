local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId = script.Name;
	Class = "Tool";
	HandlerType = "PushTool";
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;