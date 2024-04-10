local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--==
return function(player, dialog, data, mission)
	if modBranchConfigs.IsWorld("BanditsRecruitment") then
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 9 then
				dialog:SetInitiateTag("theRecruit_zarkInit");
				dialog:AddChoice("theRecruit_recruit1", function(dialog)
					dialog:AddChoice("theRecruit_recruit2", function(dialog)
						modMission:Progress(player, 63, function(mission)
							if mission.ProgressionPoint <= 10 then
								mission.ProgressionPoint = 10;
							end
						end)
					end)
				end)
				
			elseif stage == 11 then
				dialog:SetInitiateTag("theRecruit_zarkInit2");
				dialog:AddChoice("theRecruit_recruit3", function(dialog)
					dialog:AddChoice("theRecruit_recruit4", function(dialog)
						dialog:AddChoice("theRecruit_recruit5", function(dialog)
							modMission:Progress(player, 63, function(mission)
								if mission.ProgressionPoint <= 12 then
									mission.ProgressionPoint = 12;
								end
							end)
							
							task.wait(5);
							modServerManager:Travel(player, "TheMall");
						end)
					end)
				end)
				
			end
		end
	end
end
