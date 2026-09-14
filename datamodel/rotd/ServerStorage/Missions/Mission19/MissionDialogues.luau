local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local MISSION_ID = 19;
--==

-- MARK: Wilson Dialogues
Dialogues.Wilson.DialogueStrings = {
	["tickhunting_sure"]={
		Say="Sure."; 
		Face="Ugh"; 
		Reply="This annonying type of zombies keeps ticking, they run at you and tries to blow you up. I need you to get rid of them.";
	};
	["tickhunting_yeah"]={
		CheckMission=MISSION_ID;
		Say="I'm on it."; 
		Face="Smirk"; 
		Reply="Off you go solider, get back here as soon as you are done.";
	};
	["tickhunting_stillWorking"]={
		Say="Hard at work sir.."; 
		Face="Ugh"; 
		Reply="Alright, keep going.";
	};
	["tickhunting_return"]={
		Say="I got rid of as much as I could."; 
		Face="Joyful"; 
		Reply="You did great solider.";
	};
	
};

if RunService:IsServer() then
	-- MARK: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("Progress status?");
			if stage == 1 then
				dialog:AddChoice("tickhunting_stillWorking");
			elseif stage == 2 then
				dialog:AddChoice("tickhunting_return", function(dialog)
					modMission:CompleteMission(player, MISSION_ID);
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("You up for another task, solider?");
			dialog:AddChoice("tickhunting_sure", function(dialog)
				dialog:AddChoice("tickhunting_yeah", function(dialog)
					modMission:StartMission(player, MISSION_ID);
				end)
			end)
			
		end
	end
end


return Dialogues;