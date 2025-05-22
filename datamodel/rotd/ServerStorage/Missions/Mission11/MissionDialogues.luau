local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jane={};
};

local missionId = 11;
--==

-- !outline: Jane Dialogues
Dialogues.Jane.DialogueStrings = {
	["signal_radio"]={
		Say="Does that radio work?";
		Face="Suspicious"; 
		Reply="It powers on, but all I get is static and noise, can't seem to get a signal..";
	};
	["signal_repair"]={
		CheckMission=missionId;
		Say="Is there anyway to fix it?"; 
		Face="Surprise"; 
		Reply="There's a satellite on the roof, but it's too dangerous for me to go outside.";
		FailResponses = {
			{Reply="I'm not sure yet.."};
		};	
	};
	["signal_fix"]={
		Say="I can go fix it.";
		Face="Happy"; 
		Reply="That would be great.";
	};
	["signal_great"]={
		Say="It's going errr great!";
		Face="Suspicious"; 
		Reply="Alright...";
	};
	["signal_complete"]={
		Say="The satellite is repaired now, getting any signals?";
		Face="Confident"; 
		Reply="Thanks! I'll turn the dial around and see if it's catching any signals.";
	};
	["signal_distress"]={
		Say="*Listens*";
		Face="Surprise"; 
		Reply="Radio: *Static*...Any....one..out.ther..pleas..res..pond...We...are..in.. *Static*";
	};

};

if RunService:IsServer() then
	-- !outline: Jane Handler
	Dialogues.Jane.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:AddChoice("signal_radio", function(dialog)
				dialog:AddChoice("signal_repair", function(dialog)
					dialog:AddChoice("signal_fix", function(dialog)
						modMission:StartMission(player, missionId);
					end)
				end)
			end)
			
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("How's the repair going?");
			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("signal_great");
				
			else
				dialog:AddChoice("signal_complete", function(dialog)
					dialog:AddChoice("signal_distress", function(dialog)
						modMission:CompleteMission(player, missionId);
					end)
				end)
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;