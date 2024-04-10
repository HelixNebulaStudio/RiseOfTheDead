local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available
		if mission.ProgressionPoint == 1 then
		end

	elseif mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 1 then
			dialog:SetInitiateTag("banditRecruit_banditCampGate");
			dialog:AddChoice("banditRecruit_recruit1", function(dialog)
				dialog:AddChoice("banditRecruit_recruit2", function(dialog)
					modMission:Progress(player, 63, function(mission)
						if mission.ProgressionPoint <= 2 then
							mission.ProgressionPoint = 2;
						end
					end)
				end)
			end)
			
		elseif mission.ProgressionPoint == 2 then
			dialog:SetInitiate("Well?");
			dialog:AddChoice("banditRecruit_recruit3", function(dialog)
				modMission:Progress(player, 63, function(mission)
					if mission.ProgressionPoint <= 3 then
						mission.ProgressionPoint = 3;
					end
				end)

				modServerManager:TeleportToPrivateServer("BanditsRecruitment", modServerManager:CreatePrivateServer("BanditsRecruitment"), {player});
			end)
			
		end
		
	end
end
