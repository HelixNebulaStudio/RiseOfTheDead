local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		
		local stage = mission.ProgressionPoint;
		if stage == 1 then
			dialog:SetInitiate("Hey, I need a favor, and you owe me from all the healing I've done for you..");
			dialog:AddChoice("escort_init", function(dialog)
				dialog:AddChoice("escort_alright", function(dialog)
					modMission:Progress(player, 34, function(mission)
						if mission.ProgressionPoint < 2 then
							mission.ProgressionPoint = 2;
						end;
					end)
				end)
			end)
			
		elseif stage == 2 then
			dialog:SetInitiate("What are you standing around for?");
			dialog:AddChoice("escort_heal", function(dialog)
				local strangerModule = modNpc.GetPlayerNpc(player, "Stranger");
				if strangerModule and strangerModule.Humanoid then
					strangerModule.Humanoid.Health = strangerModule.Humanoid.MaxHealth;
				end
			end)
			
		elseif stage == 3 then
			dialog:SetInitiate("Took you a while.. Well?");
			dialog:AddChoice("escort_complete", function(dialog)
				modMission:CompleteMission(player, 34);
			end)
			
		end
		
	elseif mission.Type == 2 then -- Available
		
		
	elseif mission.Type == 4 then -- Failed
		local stage = mission.ProgressionPoint;
		dialog:SetInitiate("You are suppose to protect them!");
		dialog:AddChoice("escort_retry",  function(dialog)
			mission.ProgressionPoint = 1;
			modMission:StartMission(player, 34);
		end);
			
	end
end