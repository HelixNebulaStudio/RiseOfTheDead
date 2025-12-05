local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local MISSION_ID = 51;
--==

-- MARK: Wilson Dialogues
Dialogues.Wilson.DialogueStrings = {
	["qa1_hq"]={
		Face="Confident";
		Say="Sure, what's happening?"; 
		Reply="I have recieved a radio broadcast that the military is going to dispatch in a small team of inspectors into our quarantine zone for an assessment..";
	};
	["qa1_no"]={
		Face="Grumpy";
		Say="Wow, are we going to be saved?!"; 
		Reply="Unlikely. Under protocals, survivors are the least of their worries in our current situation..";
	};
	["qa1_sample"]={
		Face="Suspicious";
		Say="Oh no, then what are they going?"; 
		Reply="They are probably here to inspect the severity of the situation and perhaps retrieve some zombie samples for research.";
	};
	["qa1_contact"]={
		Face="Serious"; 
		Say="I see."; 
		Reply="We need to make contact. If we can prove ourselves useful, they will protect us. We can give them information in exchange for their help.";
	};
	["qa1_radio"]={
		CheckMission=MISSION_ID; 
		Face="Confident"; 
		Say="Okay, I'm on it."; 
		Reply="We need a stronger radio to try to broadcast our message to them.. Look for any military grade radio to try to make contact and tell them Wilson from squad B is still alive.";
	};
	
	["qa1_notyet"]={
		Face="Serious"; 
		Say="Not yet."; 
		Reply="Hurry, I don't know when they will be dispatched into our quarantine zone..";
	};

	["qa1_done"]={
		Face="Confident"; 
		Say="Yep, I've made contact from the Radio Station."; 
		Reply="Ok good, what did they say?";
	};
	["qa1_done2"]={
		Face="Surprise"; 
		Say="They say they will be dispatching the inspection team here."; 
		Reply="Here? Hmmm, that's strange. That's unlike protocol for them to directly come to us. This might not be what we think it is..";
	};
	["qa1_done3"]={
		Face="Surprise"; 
		Say="Oh, what do you mean?"; 
		Reply="Nevermind, I am just going to be optimistic for now and hope they get here quick.";
	};
	
};

if RunService:IsServer() then
	-- MARK: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("Have you made contact yet?");
			if stage == 1 then
				dialog:AddChoice("qa1_notyet");
				
			elseif stage == 6 then
				dialog:AddChoice("qa1_done", function(dialog)
					dialog:AddChoice("qa1_done2", function(dialog)
						dialog:AddChoice("qa1_done3", function(dialog)
							modMission:CompleteMission(player, MISSION_ID);
						end)
					end)
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("$PlayerName, I need your help quick.");
			dialog:AddChoice("qa1_hq", function(dialog)
				dialog:AddChoice("qa1_no", function(dialog)
					dialog:AddChoice("qa1_sample", function(dialog)
						dialog:AddChoice("qa1_contact", function(dialog)
							dialog:AddChoice("qa1_radio", function(dialog)
								modMission:StartMission(player, MISSION_ID);
							end)
						end)
					end)
				end)
			end)
			
		end
	end

end


return Dialogues;