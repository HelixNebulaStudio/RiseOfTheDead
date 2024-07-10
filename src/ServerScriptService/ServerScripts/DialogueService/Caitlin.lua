local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

return function(player, dialog, data)
	dialog:AddChoice("heal_request", function()
		if not dialog.InRange() then return end;
		modStatusEffects.FullHeal(player, 0.05);
		modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
	end)
	
	dialog:AddChoice("shop_ratShop");
end
