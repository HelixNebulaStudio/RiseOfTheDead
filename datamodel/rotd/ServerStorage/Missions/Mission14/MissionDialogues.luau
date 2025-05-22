local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Nick={};
	Jane={};
};

local missionId = 14;
--==

-- MARK: Nick Dialogues
Dialogues.Nick.DialogueStrings = {
	["pigeonPost_help"]={
		CheckMission=missionId;
		Say="What do you need help with?"; 
		Reply="I spoke to Robert before he left about his safehouse. He said they have 4 or 5 survivors, I don't quite remember..";
		FailResponses = {
			{Reply="Actually, I'm busy at the moment, come back later."};
		};
	};
	["pigeonPost_hadfive"]={
		Say="They have 5 survivors."; 
		Face="Skeptical"; 
		Reply="Oh, alright. Was there, by any chance, a person named Jane?";
	};
	["pigeonPost_yes"]={
		Say="Yes, there was a Jane there.";
		Face="Disbelief"; 
		Reply="OH THANK GOODNESS. I need you to help me let her know that I'm here, she must be worried sick.\n\nI can't really go out there, I do not know how to use a gun..";
	};
	["pigeonPost_sure"]={
		Say="Sure, what do you want me to tell her?"; 
		Face="Disbelief"; 
		Reply="Let her know that I'm alright and I'm in a safehouse. Tell her not to go out there to look for me.. It's too dangerous, when the time's right, I will come for her.";
	};
	["pigeonPost_gotit"]={
		Say="Alright, got it."; 
		Face="Oops"; 
		Reply="Thanks a lot, good luck out there.";
	};
	
	["pigeonPost_wrong"]={
		Say="Ummm, sorry but I think she isn't the Jane you know."; 
		Face="Scared"; 
		Reply="What! What do you mean?";
	};
	["pigeonPost_didntKnow"]={
		Say="She said she didn't know you."; 
		Face="Disbelief"; 
		Reply="Noooooo, where could she be??";
	};
	["pigeonPost_sayHi"]={
		Say="She told me to say hi though."; 
		Face="Disgusted"; 
		Reply="*sob*";
	};
};

-- MARK: Jane Dialogues
Dialogues.Jane.DialogueStrings = {
	["pigeonPost_what"]={
		Say="Umm hey.."; 
		Face="Confident"; 
		Reply="Hey.";
	};
	["pigeonPost_whosNick"]={
		Say="Nick wanted me to tell you that he's safe and that you do not have to worry about going out to look for him because it is dangerous outside."; 
		Face="Question";
		Reply="Oh err.. umm... Who's Nick?";
	};
	["pigeonPost_oh"]={
		Say="Oh.. Umm... I guess he thought you were the Jane he knows. It'll be hard for me to break it to him.."; 
		Face="Smile"; 
		Reply="Oh dear, anyways, tell him I said hi.";
	};

}

if RunService:IsServer() then
	-- MARK: Nick Handler
	Dialogues.Nick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint <= 2 then
				dialog:SetInitiate("Please tell her the message as soon as you can.");
			else
				dialog:SetInitiate("Have you gotten the message to her?");
				dialog:AddChoice("pigeonPost_wrong", function(dialog)
					dialog:AddChoice("pigeonPost_didntKnow", function(dialog)
						dialog:AddChoice("pigeonPost_sayHi", function(dialog)
							modMission:CompleteMission(player, missionId);
						end);
					end)
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("$PlayerName, could you help me with something?");
			dialog:AddChoice("pigeonPost_help", function(dialog)
				dialog:AddChoice("pigeonPost_hadfive", function(dialog)
					dialog:AddChoice("pigeonPost_yes", function(dialog)
						dialog:AddChoice("pigeonPost_sure", function(dialog)
							dialog:AddChoice("pigeonPost_gotit", function(dialog)
								modMission:StartMission(player, missionId);
							end)
						end)
					end)
				end)
			end)
			
		end
	end

	-- MARK: Jane Handler
	Dialogues.Jane.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:AddChoice("pigeonPost_what", function(dialog)
				dialog:AddChoice("pigeonPost_whosNick", function(dialog)
					dialog:AddChoice("pigeonPost_oh", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 3 then
								mission.ProgressionPoint = 3;
							end;
						end)
					end)
				end)
			end)
			
		end
	end
end


return Dialogues;