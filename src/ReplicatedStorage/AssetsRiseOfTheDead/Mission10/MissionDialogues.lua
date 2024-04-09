local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jefferson={};
	Wilson={};
};

local missionId = 10;
--==

-- !outline: Jefferson Dialogues
Dialogues.Jefferson.Dialogues = function()
	return {
		{Tag="infected_letmehelp"; CheckMission=missionId; Dialogue="Please let me help you.";
			Face="Frustrated"; Reply="I can't be saved, I'm infected. Don't waste your resources on me.";
			FailResponses = {
				{Reply="I don't think you can help me.."};
			};
		};
		{Tag="infected_insist"; Dialogue="It's okay, I want to help you.";
			Face="Serious"; Reply="*sigh* If you insist, please get me some antibiotics for this wound from Sunday's convenient store."};
		{Tag="infected_foundit"; Dialogue="Here's the antibiotics.";
			Face="Skeptical"; Reply="Thanks, it's best if you leave me here for now."};
		{Tag="infected_helper"; Dialogue="I can't find the antibiotics anywhere...";
			Face="Serious"; Reply="Is there a doctor you could ask the antibiotics from?"};
	};
end

-- !outline: Wilson Dialogues
Dialogues.Wilson.Dialogues = function()
	return {
		{Tag="fallen_contact"; Dialogue="*Listens*";
			Face="Surprise"; Reply="Derrick, are you there? Have you found Jefferson yet? Over...\n\n *Radio(Derrick)*: Copy, Wilson, still no signs of Jefferson. Over..."};
		{Tag="fallen_hurry"; Dialogue="*Listens*";
			Face="Skeptical"; Reply="Derrick, you got to hurry, Jefferson could be bleeding out. Over...\n\n *Radio(Derrick)*: *Static* *Static*"};
		{Tag="fallen_disconnected"; Dialogue="*Listens*";
			Face="Serious"; Reply="Derrick, do you copy?! Over...\n\n *Radio(Derrick)*: *Static* *Static*"};
		{Tag="fallen_mia"; Dialogue="*Listens*"; 
			Face="Bored"; Reply="######! Signal is dead."};
	};
end

if RunService:IsServer() then
	-- !outline: Jefferson Handler
	Dialogues.Jefferson.DialogueHandler = function(player, dialog, data, mission)
		local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

		if mission.Type == 2 then -- Available;
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Found the antibiotics yet?");
			local mission = modMission:GetMission(player, 10);
			local item, storage = modStorage.FindItemIdFromStorages("antibiotics", player);

			if item then
				dialog:AddChoice("infected_foundit", function(dialog)
					storage:Remove(item.ID);
					modMission:CompleteMission(player, 10);
					local profile = modProfile:Get(player);
					profile:Unlock("ColorPacks", "Army", true);
				end);
			elseif (os.time()-mission.StartTime) > 300 then
				dialog:AddChoice("infected_helper", function(dialog)
					if modEvents:GetEvent(player, "mission10_antibiotics") == nil then
						modEvents:NewEvent(player, {Id="mission10_antibiotics"});
					end
				end);
			end
			
		elseif mission.Type == 3 then -- Complete
			dialog:SetInitiate("Thanks again, you can leave me here for now.. I'll be fine.");
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end
	
	-- !outline: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 3 then -- Complete
			dialog:AddChoice("fallen_contact", function(dialog)
				dialog:AddChoice("fallen_hurry", function(dialog)
					dialog:AddChoice("fallen_disconnected", function(dialog)
						dialog:AddChoice("fallen_mia");
					end)
				end)
			end)
		end
	end
	
end


return Dialogues;
