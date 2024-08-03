local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Stephanie={};
};

local missionId = 9;
--==

-- !outline: Stephanie Dialogues
Dialogues.Stephanie.DialogueStrings = {		
	["specialmods_start"]={
		CheckMission=missionId; 
		Say="What did you find?";
		Face="Suspicious"; Reply="I found a way to attach special mods to your weapons.";
		FailResponses = {
			{Reply="I haven't finished reading this, but it might be something big."};
		};	
	};
	["specialmods_like"]={
		Say="Special mods?";
		Face="Confident"; 
		Reply="Yes, there's this mod called Incendiary Rounds which allows you to set the enemy you shot on fire!";
	};
	["specialmods_amazing"]={
		Say="That's amazing, how do I make such mod?";
		Face="Confident"; 
		Reply="Here's the blueprint I drafted.\n\nAsk me if you can't find the resources you need, maybe I know where you can find them.";
	};

	["guide_metalpipes"]={
		Say="Where can I find a metal pipe?";
		Face="Suspicious"; Reply="I think the Prisoner might have some...";
	};
	["guide_igniter"]={
		Say="Where can I find a igniter?";
		Face="Suspicious"; 
		Reply="I think Tanker might have some...";
	};
	["guide_gastank"]={
		Say="Where can I find a gas tank?";
		Face="Suspicious"; 
		Reply="I think Fumes might have some...";
	};
};

if RunService:IsServer() then
	
	-- !outline: Stephanie Handler
	Dialogues.Stephanie.DialogueHandler = function(player, dialog, data, mission)
		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
		
		local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Oh $PlayerName! Glad you're here, I just found out something.");
			dialog:AddChoice("specialmods_start", function(dialog)
				dialog:AddChoice("specialmods_like", function(dialog)
					dialog:AddChoice("specialmods_amazing", function(dialog)
						modMission:StartMission(player, missionId, function(successful)
							if successful then
								modBlueprints.UnlockBlueprint(player, "incendiarybp");

								dialog:AddChoice("guide_metalpipes");
								dialog:AddChoice("guide_igniter");
								dialog:AddChoice("guide_gastank");
								remoteSetHeadIcon:FireClient(player, 1, "Stephanie", "Guide");
							end
						end);
					end)
				end)
			end)
			
			
		elseif mission.Type == 1 then -- Active
			dialog:AddChoice("guide_metalpipes");
			dialog:AddChoice("guide_igniter");
			dialog:AddChoice("guide_gastank");
			remoteSetHeadIcon:FireClient(player, 1, "Stephanie", "Guide");
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;