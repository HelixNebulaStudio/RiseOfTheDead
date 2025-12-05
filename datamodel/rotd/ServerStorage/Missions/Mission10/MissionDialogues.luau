local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jefferson={};
	Wilson={};
};

local MISSION_ID = 10;
--==

-- !outline: Jefferson Dialogues
Dialogues.Jefferson.DialogueStrings = {
	["infected_foundit"]={
		Say="Here's the antibiotics.";
		Face="Skeptical"; 
		Reply="Thanks, it's best if you leave me here for now.";
	};
	["infected_helper"]={
		Say="I can't find the antibiotics anywhere...";
		Face="Serious"; 
		Reply="Is there a doctor you could ask the antibiotics from?";
	};
};

-- !outline: Wilson DialogueStrings
Dialogues.Wilson.DialogueStrings = {
	["fallen_contact"]={
		Say="*Listens*";
		Face="Surprise"; 
		Reply="Derrick, are you there? Have you found Jefferson yet? Over...\n\n *Radio(Derrick)*: Copy, Wilson, still no signs of Jefferson. Over...";
	};
	["fallen_hurry"]={
		Say="*Listens*";
		Face="Skeptical"; 
		Reply="Derrick, you got to hurry, Jefferson could be bleeding out. Over...\n\n *Radio(Derrick)*: *Static* *Static*";
	};
	["fallen_disconnected"]={
		Say="*Listens*";
		Face="Serious"; 
		Reply="Derrick, do you copy?! Over...\n\n *Radio(Derrick)*: *Static* *Static*";
		};
	["fallen_mia"]={
		Say="*Listens*"; 
		Face="Bored"; 
		Reply="######! Signal is dead.";
	};
};

if RunService:IsServer() then
	-- !outline: Jefferson Handler
	Dialogues.Jefferson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

		local mission = modMission:GetMission(player, MISSION_ID);
		if mission.Type == 2 then -- Available;
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Found the antibiotics yet?");
			local item, storage = modStorage.FindItemIdFromStorages("antibiotics", player);

			if item then
				dialog:AddChoice("infected_foundit", function(dialog)
					local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItems.Generics.UnlockPack);
					modUnlockPack.UnlockPack(player, "ColorPacks", "Army");

					storage:Remove(item.ID);
					modMission:CompleteMission(player, MISSION_ID);
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