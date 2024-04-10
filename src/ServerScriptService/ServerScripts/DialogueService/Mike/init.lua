local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

return function(player, dialog, data)
	local mission45 = modMission:GetMission(player, 45);
	if mission45 and mission45.ProgressionPoint >= 1 then
		dialog:AddChoice("travel_prison");
	end
	
	dialog:AddChoice("general_inprison");
	dialog:AddChoice("general_how", function(dialog)
		dialog:AddChoice("general_how2");
	end);
	
end
