local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Erik={};
};

local missionId = 20;
--==

-- MARK: Erik Dialogues
Dialogues.Erik.Dialogues = function()
	return {
		{CheckMission=missionId; Tag="eightlegs_sure"; Dialogue="What do you need help with?";
			Face="Worried"; Reply="The Zpider is making a lot of noise and I have a hard time sleeping because of it..\nCould you kill it for me please?";
			FailResponses = {
				{Reply="I'm okay for now, come back later."};
			};
		};
		{Tag="eightlegs_yeah"; Dialogue="Absoutely!";
			Face="Smile"; Reply="Thanks.."};
		{Tag="eightlegs_almost"; Dialogue="Still trying to get rid of it, sit tight.";
			Face="Smile"; Reply="Oh.. okay."};
		{Tag="eightlegs_return"; Dialogue="I killed it. You don't have to worry about it now.";
			Face="Joyful"; Reply="Thanks a lot.."};
		
	};
end

if RunService:IsServer() then
	-- MARK: Erik Handler
	Dialogues.Erik.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("Is.. is it gone?");
			if stage == 1 then
				dialog:AddChoice("eightlegs_almost");

			elseif stage == 2 then
				dialog:AddChoice("eightlegs_return", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)

			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, can you help me with something?");
			dialog:AddChoice("eightlegs_sure", function(dialog)
				dialog:AddChoice("eightlegs_yeah", function(dialog)
					modMission:StartMission(player, missionId);
				end)

			end)
			
		end
	end
end


return Dialogues;