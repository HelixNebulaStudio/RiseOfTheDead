local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Dr. Deniski"]={};
	Carlos={};
};

local missionId = 8;
--==

-- !outline: Dr. Deniski Dialogues
Dialogues["Dr. Deniski"].Dialogues = function()
	return {		
		{Tag="bandageup_start"; CheckMission=missionId; Dialogue="Hey doctor, how can I heal myself when I'm outside?"; 
			Face="Surprise"; Reply="I was researching the zombie blood from the arm you gave me earlier, it was pretty strange. They are apparently not infectious, something else must be turning people into zombies..";
			FailResponses = {
				{Reply="Hold on, I'm quite busy right now.."};
			};
		};
		{Tag="bandageup_get"; Dialogue="oh no.."; 
			Face="Confident"; Reply="Anyways, I made this medkit blueprint which you can use to heal yourself, wait while I look for where I placed it... *searches*"};
		{Tag="bandageup_wait"; Dialogue="*waits*"; 
			Face="Happy"; Reply="Ah, here it is. Here you go.";
		};
	};
end

-- !outline: Carlos Dialogues
Dialogues.Carlos.Dialogues = function()
	return {		
		{Tag="pillsHere_where"; Dialogue="Hey, where's can I find medicine?";
			Face="Excited"; Reply="It's nearby that storage crate over there."};
	};
end

if RunService:IsServer() then
	-- !outline: Dr. Deniski Handler
	Dialogues["Dr. Deniski"].DialogueHandler = function(player, dialog, data, mission)
		local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.Type == 2 then -- Available;
			dialog:AddChoice("bandageup_start", function(dialog)
				dialog:AddChoice("bandageup_get", function(dialog)
					dialog:AddChoice("bandageup_wait", function(dialog)
						modMission:StartMission(player, 8, function(successful)
							modBlueprints.UnlockBlueprint(player, "medkitbp");
						end);
					end);
				end);
			end);
			
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Having trouble making the medkit? Look for cloth.");
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end
	

	-- !outline: Carlos Handler
	Dialogues.Carlos.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			dialog:AddChoice("pillsHere_where");
			
		end
	end

end


return Dialogues;