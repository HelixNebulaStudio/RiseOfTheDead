local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

return function(player, dialog, data)
	local mission62 = modMission:GetMission(player, 62);
	if mission62 and mission62.Type == 1 then return end;
	
	local mission30 = modMission:GetMission(player, 30);
	if mission30 and mission30.ProgressionPoint > 1 then
		dialog:AddChoice("general_fast");
	end
end
