local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);


--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available
		dialog:SetInitiate("Howdy, what can I do for ya?");
		dialog:AddChoice("investigation_zombieface", function(dialog)
			dialog:AddChoice("investigation_fast", function(dialog)
				dialog:AddChoice("investigation_zark", function(dialog)
					dialog:AddChoice("investigation_keepEye", function(dialog)
						modMission:StartMission(player, 52);
					end)
				end)
			end)
		end)
		
	elseif mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 9 then
			dialog:SetInitiate("Ugghh, I'm... losing.. a lot of.. blood..");
			modMission:Progress(player, 52, function(mission)
				mission.ProgressionPoint = 10;
			end)
			
		elseif mission.ProgressionPoint == 10 then
			dialog:SetInitiate("Ugghh, hurry..");
			
		elseif mission.ProgressionPoint == 11 then
			dialog:SetInitiate("Ugghh, hurry..");
			dialog:AddChoice("investigation_patchJoseph", function(dialog)
				modMission:Progress(player, 52, function(mission)
					mission.ProgressionPoint = 12;
				end)
			end)
			
		elseif mission.ProgressionPoint == 19 then
			dialog:SetInitiate("Thanks $PlayerName, I took some medicine to ease the pain. Nate and I will be heading back to the community so I can rest there.");
			dialog:AddChoice("investigation_complete", function(dialog)
				dialog:AddChoice("investigation_complete2", function(dialog)
					modMission:CompleteMission(player, 52);
				end)
			end)
			
		elseif mission.ProgressionPoint >= 4 then
			dialog:SetInitiate("Ugghh..");
			
		elseif mission.ProgressionPoint <= 3 then
			dialog:SetInitiate("Keeping an eye on him, hasn't done anything suspicious yet..");
		end

	elseif mission.Type == 3 then
		if modBranchConfigs.IsWorld("TheResidentials") then
			if data:Get("lostArm") == nil then
				dialog:SetInitiate("You're back, $PlayerName..");
				dialog:AddChoice("lostArm_muchBetter", function(dialog)
					data:Set("lostArm", true);
				end);
			end
		end
	end
end