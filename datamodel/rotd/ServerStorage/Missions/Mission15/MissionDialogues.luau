local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Stephanie={};
};

local missionId = 15;
--==

-- MARK: Stephanie Dialogues
Dialogues.Stephanie.DialogueStrings = {
	["chainReaction_start"]={
		CheckMission=missionId;
		Say="Interesting, what is it?";
		Face="Confident"; 
		Reply="Well, this one's called Electric Charge, I believe it damages nearby enemeis, seems useful for taking out multiple enemies.";
		FailResponses = {
			{Reply="Stephanie hasn't finished reading the book yet.."};
		};
	};
	["chainReaction_useful"]={
		Say="That's definitely useful."; 
		Face="Skeptical"; 
		Reply="Yeah, I finished reading the book and there are two more of these elemental mods which I couldn't figure out how to make the blueprint for.";
	};
	["chainReaction_otherTwo"]={
		Say="Which are they?";
		Face="Surprise"; 
		Reply="Frost and toxic.. I've worked out the fire and electricity mods blueprints now, but for the other two, I'm not sure what the materials are. Anyways, I'll call you when I figured it out.";
	};
	
	["guide_battery"]={
		Say="Where can I find batteries?";
		Reply="I think there might be some in the warehouse, if not maybe corrosive might have some...";
	};
	["guide_wires"]={
		Say="Where can I find wires?";
		Reply="I think there might be some in the factory, if not maybe zpider might have some...";
	};
	
};

if RunService:IsServer() then
	-- MARK: Stephanie Handler
	Dialogues.Stephanie.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modBlueprints = shared.require(game.ServerScriptService.ServerLibrary.Blueprints);

		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
		
		local npcName = dialog.Name;

		if mission.Type == 1 then -- Active
			dialog:AddChoice("guide_battery");
			dialog:AddChoice("guide_wires");
			remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("$PlayerName, I worked out another interesting mod blueprint. They almost seems as if they are elemental.", "Surprise");
			dialog:AddChoice("chainReaction_start", function(dialog)
				dialog:AddChoice("chainReaction_useful", function(dialog)
					dialog:AddChoice("chainReaction_otherTwo", function(dialog)
						modMission:StartMission(player, missionId, function(successful)
							if successful then
								modBlueprints.UnlockBlueprint(player, "electricbp");
								
								dialog:AddChoice("guide_battery");
								dialog:AddChoice("guide_wires");
								remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
							end
						end);
					end)
				end)
			end)
			
		end
	end
end


return Dialogues;