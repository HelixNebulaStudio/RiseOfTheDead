local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Patrick={};
	Robert={};
	Rachel={};
};

local MISSION_ID = 38;
--==

-- !outline: Patrick Dialogues
Dialogues.Patrick.DialogueStrings = {
	["notRight_start1"]={
		CheckMission=MISSION_ID; 
		Face="Disgusted";
		Say="I will avenge him.";
		Reply="Alright, well, don't let your emotions get to you."};
	["notRight_start2"]={
		CheckMission=MISSION_ID;
		Face="Disgusted";
		Say="He was a good man.";
		Reply="Salute to that..";
	};
};

-- !outline: Robert Dialogues
Dialogues.Robert.DialogueStrings = {
	["notRight_fast"]={
		Face="Surprise";
		Say="Uhhh.. How were you running so fast?!";
		Reply="Whaat? I was?";
	};
	["notRight_where"]={
		Face="Question";
		Say="And where did you disapeared to?!";
		Reply="I was.. I err.. I heard a cry for help from another community.";
	};
	["notRight_bandits"]={
		Face="Joyful";
		Say="We thought the bandits got to you!!";
		Reply="Oh err.. They didn't. Heh heh, I got away.";
	};
	["notRight_worried"]={
		Face="Worried";
		Say="We were worried sick!";
		Reply="Oh.. sorry. Stay here, this is a nice place.";
	};
};

-- !outline: Rachel Dialogues
Dialogues.Rachel.DialogueStrings = {
	["notRight_stan"]={
		Face="Disgusted";
		Say="I'm sorry.. The bandits, they.. They murdered Stan..";
		Reply="Noooo.. I can't believe it has come to this..";
	};
};

if RunService:IsServer() then
	-- !outline: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available
			dialog:SetInitiate("I am really sorry for what happen to Stan. I did not expect that.", "Disgusted");
			dialog:AddChoice("notRight_start1", function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)
			dialog:AddChoice("notRight_start2", function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)

		end
	end

	-- !outline: Robert Handler
	Dialogues.Robert.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("Oh.. Err.. Hey, $PlayerName", "Surprise");
			if mission.ProgressionPoint == 6 then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 7 then mission.ProgressionPoint = 7; end;
				end)
			end

			dialog:AddChoice("notRight_fast", function(dialog)
				dialog:AddChoice("notRight_where", function(dialog)
					dialog:AddChoice("notRight_bandits", function(dialog)
						dialog:AddChoice("notRight_worried", function(dialog)
							modMission:CompleteMission(player, MISSION_ID);
						end)
					end)
				end)
			end)
		end
	end
	
	-- !outline: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("Umm, $PlayerName. Where's Stan?", "Worried");

			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("notRight_stan", function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 2 then
							mission.ProgressionPoint = 2;
						end;
					end)
				end)
			end

		end
	end
end


return Dialogues;