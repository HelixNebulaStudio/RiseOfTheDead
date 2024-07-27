local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local missionId = 13;
--==

-- !outline: Wilson Dialogues
Dialogues.Wilson.Dialogues = function()
	return {
		{Tag="crowdcontrol_what"; Dialogue="What do you need help with?"; 
			Face="Serious"; Reply="I have intel that the population of the zombies is growing rapidly.. I've heard you are very capable of taking out large amount of zombies."};
		{CheckMission=missionId; Tag="crowdcontrol_yeah"; Dialogue="Yeah, I can."; 
			Face="Joyful"; Reply="Great! This will really help me out in finding my partner. Kill about a hundred zombies will do.";
			FailResponses = {
				{Reply="You're gonna need bigger weapons before you do this.."};
			};};
		{Tag="crowdcontrol_stillWorking"; Dialogue="Still working on it.."; 
			Face="Smirk"; Reply="Alright, keep at it."};
		{Tag="crowdcontrol_return"; Dialogue="I think I killed about a hundred zombies..."; 
			Face="Happy"; Reply="That'll be good for now, thanks for your help."};
		
	};
end

if RunService:IsServer() then
	-- !outline: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("How's the progress?");
			if stage == 1 then
				dialog:AddChoice("crowdcontrol_stillWorking");
			elseif stage == 2 then
				dialog:AddChoice("crowdcontrol_return", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, you! I need your help.");
			dialog:AddChoice("crowdcontrol_what", function(dialog)
				dialog:AddChoice("crowdcontrol_yeah", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
end


return Dialogues;