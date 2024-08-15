local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Joseph={};
};

local missionId = 81;
--==

-- MARK: Rachel DialogueStrings
Dialogues.Joseph.DialogueStrings = {
	["fotl_init"]={
		Face="Skeptical";
		Reply="Should be here by now.. Oh hello, $PlayerName.";
	};
	["fotl_prologue1"]={
		CheckMission=missionId;
		Face="Skeptical"; 
		Say="Hey Joseph, what was that about something should be here now?";
		Reply="Yeah, these Rats.. I made a deal with them for some walkie talkies a while ago..";
		FailResponses = {
			{Reply="We'll wait a while and see when it will be delivered."};
		};
	};
	["fotl_prologue2"]={
		Face="Skeptical";
		Say="...";
		Reply="...Til this day, they have yet to deliver.";
	};
	["fotl_prologue3"]={
		Face="Suspicious";
		Say="Hmmm, would you like me to talk to them?";
		Reply="Are you sure? You will have to head to the W.D. Harbor to talk to them.";
	};
	["fotl_prologue4"]={
		Face="Confident";
		Say="Yeah, I don't mind. I can go talk to them.";
		Reply="In that case, it's a box of 3 walkie talkies. Good luck out there!";
	};

};

if RunService:IsServer() then
	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available
			dialog:SetInitiateTag("fotl_init");

			dialog:AddChoice("fotl_prologue1", function(dialog)
				dialog:AddChoice("fotl_prologue2", function(dialog)
					dialog:AddChoice("fotl_prologue3", function(dialog)
						dialog:AddChoice("fotl_prologue4", function(dialog)
							modMission:StartMission(player, missionId);
						end)
					end)
				end)
			end)

		elseif mission.Type == 1 then -- Active

			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("I swear if we were scammed by those Rats..", "Suspicious");

			end

		end
	end
end


return Dialogues;