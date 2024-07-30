local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

return function(player, dialog, dialogueData)
	local mission10 = modMission:GetMission(player, 10);
	if mission10 == nil then
		dialog:InitDialog{
			Text="GET BACK! Stay away from me, I am infected.";
			Face="Frustrated";
		}
		dialog:AddChoice("infected_letmehelp", function(dialog)
			dialog:AddChoice("infected_insist", function(dialog)
				modMission:StartMission(player, 10);
			end)
		end)
		
	end
end
