local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);

return function(player, dialog, data)
	dialog:AddChoice("general_takenOver");
	dialog:AddChoice("general_russellSaved");
	dialog:AddChoice("general_howsNick", function(dialog)
		--data:Set("Affinity", (data:Get("Affinity") or 0)+1);
	end);
end
