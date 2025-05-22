local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Joseph={};
};

local missionId = 56;
--==

-- MARK: Joseph Dialogues
Dialogues.Joseph.DialogueStrings = {
	["eotl_init"]={
		Face="Happy"; 
		Reply="Welcome back, $PlayerName.";
	};
	["eotl_howsarm"]={
		Face="Skeptical";
		Say="How's your arm, Joseph?"; 
		Reply="Thank god it was just my arm, it could have been worse.";
	};
	["eotl_patchup"]={
		CheckMission=missionId; 
		Face="Skeptical";
		Say="Good to hear it, what should I do about Robert and the hole he escaped through?"; 
		Reply="Nate patched up the hole a bit, I don't recommend going after him alone.. But it's up to you, I know you can take care of yourself.";
	};
};


if RunService:IsServer() then
	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("So you have decided to follow after him aren't you?");
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiateTag("eotl_init");
			dialog:AddChoice("eotl_howsarm", function(dialog)
				dialog:AddChoice("eotl_patchup", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
end


return Dialogues;