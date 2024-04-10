local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available

	elseif mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		if stage == 1 then
			dialog:AddChoice("investigation_robert", function(dialog)
				dialog:AddChoice("investigation_face", function(dialog)
					modMission:Progress(player, 52, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end
					end)
				end)
			end)
			
		elseif stage == 12 then
			dialog:SetInitiate("...");
			
			dialog:AddChoice("investigation_wakeUp", function(dialog)
				modMission:Progress(player, 52, function(mission)
					mission.ProgressionPoint = 13;
				end)
			end)
			
		elseif stage == 13 then
			dialog:SetInitiate("...What.. happened?");
			
			dialog:AddChoice("investigation_wHappen", function(dialog)
				modMission:Progress(player, 52, function(mission)
					mission.ProgressionPoint = 14;
				end)
			end)
		end
	end
end
