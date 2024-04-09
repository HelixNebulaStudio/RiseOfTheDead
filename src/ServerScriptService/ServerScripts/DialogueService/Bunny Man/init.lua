local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);


return function(player, dialog, data)
	if modMission:GetMission(player, 31) == nil then
		dialog:AddChoice("egghunt_init", function(dialog)
			dialog:AddChoice("egghunt_find", function(dialog)
				modMission:StartMission(player, 31);
			end)
		end)
	end
end
