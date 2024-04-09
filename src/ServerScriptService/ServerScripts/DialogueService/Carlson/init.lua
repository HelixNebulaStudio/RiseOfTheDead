local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

return function(player, dialog, data)	
	local mission18 = modMission:GetMission(player, 18);
	if mission18 == nil or mission18.Type ~= 1 or mission18.ProgressionPoint >= 9 then
		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player);
		end)
	end
end