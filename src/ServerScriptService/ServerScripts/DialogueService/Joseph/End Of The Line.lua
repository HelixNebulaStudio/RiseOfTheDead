local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);

--==
return function(player, dialog, data, mission)
	
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("So you have decided to follow after him aren't you?");
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiateTag("eotl_init");
		dialog:AddChoice("eotl_howsarm", function(dialog)
			dialog:AddChoice("eotl_patchup", function(dialog)
				modMission:StartMission(player, 56);
			end)
		end)
		
	end
end
