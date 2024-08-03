local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Victor={};
};

local missionId = 41;
--==

-- MARK: Victor Dialogues
Dialogues.Victor.DialogueStrings = {
	["vt2_cultist"]={
		Face="Suspicious";
		Say="A group of cultists are hunting me, and one of them dropped this note."; 
		Reply="Oh yeah, I forgot to tell you, the tombs were apart of their lair. ";
	};
	["vt2_cultist2"]={
		Face="Grumpy";
		Say="Why do they call you The Venator?"; 
		Reply="Dude, that doesn't matter. What matters is getting rid of the cultist. What else does the note say?";
	};
	["vt2_cultist3"]={
		Face="Suspicious";
		Say="Umm, \"retrieve the mask immediately before they unleash hellfire upon everyone\".. What do they mean by that?"; 
		Reply="Err, umm, yeah.. *Looks away* I don't know either.. Like I said, what matters is getting rid of these cultists.";
	};
	
	["vt2_outfit"]={
		Face="Skeptical";
		Say="What should I do?"; 
		Reply="Disguise yourself with. They don't know each other so that'll make them question whether you are one of them.";
	};
	
};

if RunService:IsServer() then
	-- MARK: Victor Handler
	Dialogues.Victor.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active;
			if mission.ProgressionPoint == 3 then
				local gaveMask = data:Get("gaveMask");
				if gaveMask then
					dialog:SetInitiate("What's up?", "Bored");
				else
					dialog:SetInitiate("What do you want?", "Bored");
				end
				
				dialog:AddChoice("vt2_cultist", function(dialog)
					dialog:AddChoice("vt2_cultist2", function(dialog)
						dialog:AddChoice("vt2_cultist3", function(dialog)
							dialog:AddChoice("vt2_outfit", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint <= 3 then
										mission.ProgressionPoint = 4;
									end;
								end)
							end)
						end)
					end)
				end)
				
			else
				dialog:SetInitiate("Hmmm..", "Bored");
				
			end
			
		end
	end
end


return Dialogues;