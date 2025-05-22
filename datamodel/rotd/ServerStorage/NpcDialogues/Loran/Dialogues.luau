local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Face="Ugh";
		Reply="Ugn, it's you..";
	};
	["init2"]={
		Face="Ugh";
		Reply="Not interested, shoo.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["shop_banditShop"]={
		Say="Do you sell anything?";
		Reply="What do you want..?";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		if modMission:IsComplete(player, 63) then
			dialog:AddChoice("shop_banditShop", function()
				local npcModel = dialog.Prefab;
				if npcModel:FindFirstChild("shopInteractable") then
					dialog:InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart, "interact");
				end
			end);
			
		end
	end 
end

return Dialogues;