local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local missionId = 51;
--==

-- MARK: Wilson Dialogues
Dialogues.Wilson.Dialogues = function()
	return {
		{Tag="qa1_hq"; Face="Confident";
			Dialogue="Sure, what's happening?"; 
			Reply="I have recieved a radio broadcast that the military is going to dispatch in a small team of inspectors into our quarantine zone for an assessment.."};
		{Tag="qa1_no"; Face="Grumpy";
			Dialogue="Wow, are we going to be saved?!"; 
			Reply="Unlikely. Under protocals, survivors are the least of their worries in our current situation.."};
		{Tag="qa1_sample"; Face="Suspicious";
			Dialogue="Oh no, then what are they going?"; 
			Reply="They are probably here to inspect the severity of the situation and perhaps retrieve some zombie samples for research."};
		{Tag="qa1_contact"; Face="Serious"; 
			Dialogue="I see."; 
			Reply="We need to make contact. If we can prove ourselves useful, they will protect us. We can give them information in exchange for their help."};
		{Tag="qa1_radio"; CheckMission=missionId; Face="Confident"; 
			Dialogue="Okay, I'm on it."; 
			Reply="We need a stronger radio to try to broadcast our message to them.. Look for any military grade radio to try to make contact and tell them Wilson from squad B is still alive."};
		
		{Tag="qa1_notyet"; Face="Serious"; 
			Dialogue="Not yet."; 
			Reply="Hurry, I don't know when they will be dispatched into our quarantine zone.."};
	
		{Tag="qa1_done"; Face="Confident"; 
			Dialogue="Yep, I've made contact from the Radio Station."; 
			Reply="Ok good, what did they say?"};
		{Tag="qa1_done2"; Face="Surprise"; 
			Dialogue="They say they will be dispatching the inspection team here."; 
			Reply="Here? Hmmm, that's strange. That's unlike protocol for them to directly come to us. This might not be what we think it is.."};
		{Tag="qa1_done3"; Face="Surprise"; 
			Dialogue="Oh, what do you mean?"; 
			Reply="Nevermind, I am just going to be optimistic for now and hope they get here quick."};
		
	};
end

if RunService:IsServer() then
	-- MARK: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("Have you made contact yet?");
			if stage == 1 then
				dialog:AddChoice("qa1_notyet");
				
			elseif stage == 6 then
				dialog:AddChoice("qa1_done", function(dialog)
					dialog:AddChoice("qa1_done2", function(dialog)
						dialog:AddChoice("qa1_done3", function(dialog)
							modMission:CompleteMission(player, missionId);
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
								modMission:StartMission(player, missionId);
							end)
						end)
					end)
				end)
			end)
			
		end
	end

end


return Dialogues;