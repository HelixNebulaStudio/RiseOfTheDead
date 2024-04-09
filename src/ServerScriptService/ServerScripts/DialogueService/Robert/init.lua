local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

return function(player, dialog, data)
	dialog:AddChoice("general_salads");
	dialog:AddChoice("general_funny");
end
