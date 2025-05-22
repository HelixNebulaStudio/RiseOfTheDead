local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Dr. Deniski"]={};
};

local missionId = 4;
--==

-- MARK: Dr. Deniski Dialogues
Dialogues["Dr. Deniski"].DialogueStrings = {
	["lendAHand_start"]={
		CheckMission=missionId; 
		Say="Sure, how can I help you?"; 
		Reply="I'm doing some experiments and I need a zombie arm, if you can find me one, that would be great!";
		FailResponses = {
			{Reply="Hahah, if you want to help, you'll need to prove yourself first."};
		};
	};
	["lendAHand_complete"]={
		Say="Here you go..."; 
		Reply="Thank you, here's something for your troubles.";
	};
};

if RunService:IsServer() then
	-- MARK: Dr. Deniski Handler
	Dialogues["Dr. Deniski"].DialogueHandler = function(player, dialog, data, mission)
		local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:InitDialog{
				Reply="Hey friend, can you do me a favor?";
				Face="Smirk";
			}
			dialog:AddChoice("lendAHand_start", function(dialog)
				modMission:StartMission(player, missionId);
			end);
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Have you found a zombie arm yet?");
			local storage = modStorage.Get("Inventory", player);
			local found = storage and storage:FindByItemId("zombiearm") or nil;

			if found then
				dialog:AddChoice("lendAHand_complete", function(dialog)
					local list = modStorage.ListItemIdFromStorages("zombiearm", player);
					for a=1, #list do
						list[a].Storage:Remove(list[a].Item.ID);
					end
					modMission:CompleteMission(player, missionId);
				end);
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;