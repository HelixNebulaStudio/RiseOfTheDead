local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Molly={};
};

local missionId = 34;
--==

-- MARK: Molly Dialogues
Dialogues.Molly.DialogueStrings = {
	["escort_init"]={
		Say="Sure, how can I help?"; 
		Reply="So.. This person wants to get somewhere, could you escort the person there?";
	};

	["escort_alright"]={
		Say="Sure, hope it's not far.."; 
		Reply="Mhm.. Alright, get going..";
	};
		
	["escort_heal"]={
		Say="Could you heal the person?"; 
		Reply="Ugh, how hard is it just to escort someone to some place. Here, healed.";
	};
	
	["escort_retry"]={
		Say="Sorry, I should be more focused. Can we try again?"; 
		Reply="Alright, be careful this time!";
	};
	
	["escort_complete"]={
		Say="It's done, we've safely arrived to the destination."; 
		Reply="Hmmm.. Good job I guess, come back next time for another one.";
	};
	
};

if RunService:IsServer() then
	-- MARK: Molly Handler
	Dialogues.Molly.DialogueHandler = function(player, dialog, data, mission)
		local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			
			local stage = mission.ProgressionPoint;
			if stage == 1 then
				dialog:SetInitiate("Hey, I need a favor, and you owe me from all the healing I've done for you..");
				dialog:AddChoice("escort_init", function(dialog)
					dialog:AddChoice("escort_alright", function(dialog)
						modMission:Progress(player, missionId, function(mission)
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
					modMission:CompleteMission(player, missionId);
				end)
				
			end
			
		elseif mission.Type == 2 then -- Available
			
			
		elseif mission.Type == 4 then -- Failed
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("You are suppose to protect them!");
			dialog:AddChoice("escort_retry",  function(dialog)
				mission.ProgressionPoint = 1;
				modMission:StartMission(player, missionId);
			end);
				
		end
	end
end


return Dialogues;