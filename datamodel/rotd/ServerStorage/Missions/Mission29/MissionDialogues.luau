local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Hilbert={};
	["Dr. Deniski"]={};
	Lennon={};
};

local MISSION_ID = 29;
--==

-- !outline: Hilbert Dialogues
Dialogues.Hilbert.DialogueStrings = {		
	["labAssistant_start"]={
		Say="*Picks up note*";
		Reply="Note: Elr1Orj#996\nVshflphq H55 dqg J85 lv frqiluphg wr kdv hvfdshg. Vljqv vkrzv wkdw wkh lqihfwru kdv ehhq wr wkh vhfwru, lw pxvw kdyh frqwdplqdwhg uhohdvhg wkh vshflphqv.\n-Kloehuw Z.";
	};
	["labAssistant_note"]={
		CheckMission=MISSION_ID;
		Say="What is this.. It's totally unintelligible.. *Notices BioX symbol on the back of the note*";
		Reply="*still dead*";
		FailResponses = {
			{Reply="..."};
		};	
	};
};

-- !outline: Dr. Deniski Dialogues
Dialogues["Dr. Deniski"].DialogueStrings = {		
	["labAssistant_hilbert"]={
		Say="Yeah, I need some help. I found this note on a dead scientist named Hilbert. Do you know anything about him?";
		Face="Suspicious"; 
		Reply="Hmmm, I've heard of the name before, could be a BioX scientist.. Can I see the note?";
	};
	["labAssistant_note"]={
		Say="Sure, I think it's a cipher though, not sure how to read it.";
		Face="Confident"; 
		Reply="Ahhh, hahah, my friend, this looks like children's cipher, wait while I decipher this.";
	};
	["labAssistant_wait"]={
		Say="*wait*";
		Face="Confident"; 
		Reply="Hmmm, okay I got it. It says something about some specimens has escaped something called the \"Sector\" and about another creature called the Infector. That's all I can decipher, hope it helps.";
	};
	["labAssistant_helped"]={
		Say="That definitely helps, thanks a lot!";
		Face="Happy"; 
		Reply="Any time!";
	};
};

-- !outline: Lennon Dialogues
Dialogues.Lennon.DialogueStrings = {		
	["labAssistant_yes"]={
		Say="Oh.. err.. umm, do you know that scientist guy in the caves named Hilbert?"; 
		Face="Skeptical"; 
		Reply="Nooo, but he was in a rush, ran out that compound over there. I think I heard him saying something in Russian.";
	};
	["labAssistant_note"]={
		Say="Thanks, here's another thing. I picked up this blue note, I can't seem to understand what it's about. Can you read this? *shows note*"; 
		Face="Suspicious"; 
		Reply="Hmmm, yes.. I think I can read this.. It's says \"Please remember to flush the toliet.\"..";
	};
	["labAssistant_disbelieve"]={
		Say="*nods in disbelief* Okay.. thanks.."; 
		Face="Happy"; 
		Reply="You're welcome. :>";
	};
};

if RunService:IsServer() then
	-- !outline: Hilbert Handler
	Dialogues.Hilbert.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("*Still pretty dead*");

		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("*dead body holding on to a blue note*");
			dialog:AddChoice("labAssistant_start", function(dialog)
				dialog:AddChoice("labAssistant_note", function(dialog)
					modMission:StartMission(player, MISSION_ID);
				end)
			end)

		end
	end
	
	-- !outline: Dr. Deniski Handler
	Dialogues["Dr. Deniski"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Oh hey $PlayerName, it's been a while..", "Happy");
				dialog:AddChoice("labAssistant_hilbert", function(dialog)
					dialog:AddChoice("labAssistant_note", function(dialog)
						dialog:AddChoice("labAssistant_wait", function(dialog)
							dialog:AddChoice("labAssistant_helped", function(dialog)
								modMission:CompleteMission(player, MISSION_ID);
							end)
						end)
					end)
				end)
			end
		end
	end

	-- !outline: Lennon Handler
	Dialogues.Lennon.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("Ski ba bop ba dop bop...", "Bored");
				dialog:AddChoice("labAssistant_yes", function(dialog)
					dialog:AddChoice("labAssistant_note", function(dialog)
						dialog:AddChoice("labAssistant_disbelieve", function(dialog)
							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint <= 1 then
									mission.ProgressionPoint = 2;
								end;
							end)
						end)
					end)
				end)
			end
		end
	end
end


return Dialogues;