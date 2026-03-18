local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--=
local Dialogues = {
	Wilson={};
	["Military Radio"]={};
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


-- MARK: Military Radio Dialogues
Dialogues["Military Radio"].DialogueStrings = {
	["qa1_radio1s"] = {
		Say = `Hello?! Does anyone copy on this frequency?`;
		Reply = `*Static* ... *Static*`;
	};
	["qa1_radio1r"] = {
		Say = `*Listens*`;
		Reply = `*Static*\nYep, ten-four. We copy loud and clear. Please identify yourself. *Static*`;
	};
	["qa1_radio2s"] = {
		Say = `I am $PlayerName, I am requesting for help. I was sent by Wilson from squad B. He is still alive.`;
		Reply = `*Static* ... *Static*`;
	};
	["qa1_radio2r"] = {
		Say = `*Listens*`;
		Reply = `*Static*\nCopy, please hold.\n\n<i>Commander, we have a survivor on the radio. He claims Wilson from squad B is alive and sent him.</i>`;
	};
	["qa1_radio3s"] = {
		Say = "*Listens*";
		Reply = `*Static* ... *Static*`;
	};
	["qa1_radio3r"] = {
		Say = "*Listens*";
		Reply = "*Static*\nCommander: Wilson is still alive?! Hello? This is commander Leo. Please state your location.";
	};
	["qa1_radio4"] = {
		Say = "We are located in the Sunday's Convenience Store near the Wrighton Dale Bank..";
		Reply = "*Static*\nCopy. We will be dispatching an inspection team there... *static*";
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
				
			elseif stage == 4 then
				dialog:AddChoice({"qa1_done"; "qa1_done2"; "qa1_done3"}, function(dialog)
					modMission:CompleteMission(player, MISSION_ID);
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

	-- MARK: Radio Interactable Handler
	Dialogues["Military Radio"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate(`*static* *static*`);

			if mission.ProgressionPoint == 3 then
				dialog:AddChoice({"qa1_radio1s"; "qa1_radio1r";}, function(dialog)
					modAudio.Play("RadioChatter", dialog.Character);

					dialog:AddChoice({"qa1_radio2s"; "qa1_radio2r";}, function(dialog)
						modAudio.Play("RadioChatter2", dialog.Character);

						dialog:AddChoice({"qa1_radio3s"; "qa1_radio3r"}, function(dialog)
							modAudio.Play("RadioChatter3", dialog.Character);

							dialog:AddChoice("qa1_radio4", function(dialog)
								modAudio.Play("RadioStatic", dialog.Character);
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint == 3 then
										mission.ProgressionPoint = 4;
									end;
								end)

							end)
						end)
					end)
				end)
			end
		end
	end

end


return Dialogues;