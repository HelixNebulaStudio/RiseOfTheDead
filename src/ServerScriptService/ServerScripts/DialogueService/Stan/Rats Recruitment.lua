local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--==
return function(player, dialog, data, mission)
	if modBranchConfigs.IsWorld("SectorE") then
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 6 then
				
			elseif stage == 7 then
				dialog:SetInitiate("It.. burns..\n\nIt's you.. $PlayerName..");

				dialog:AddChoice("ratRecruit_chamber1", function(dialog)
					dialog:AddChoice("ratRecruit_chamber2", function(dialog)
						dialog:AddChoice("ratRecruit_chamber3", function(dialog)
							modMission:Progress(player, 62, function(mission)
								mission.ProgressionPoint = 8;
							end)

						end)
					end)
				end)

			elseif stage == 8 then
				dialog:SetInitiate("Use the terminal, look around if you don't know how, I think Eugene wrote down some notes.");

			elseif stage == 9 then
				dialog:SetInitiate("Thanks, $PlayerName..");
				dialog:AddChoice("ratRecruit_chamber4", function(dialog)
					dialog:AddChoice("ratRecruit_chamber5", function(dialog)
						dialog:AddChoice("ratRecruit_chamber6", function(dialog)
							modMission:Progress(player, 62, function(mission)
								mission.ProgressionPoint = 10;
							end)
							
						end)
					end)
					
				end)
				
			end
		end
		
	end
end