local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

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
				local npcChar = dialog.Character;

				local shopInteractConfig = npcChar:FindFirstChild("ShopInteractable");
				if shopInteractConfig == nil then
					shopInteractConfig = modInteractables.createInteractable("Shop");
					shopInteractConfig.Name = "ShopInteractable";
					shopInteractConfig:SetAttribute("ShopType", "Bandits");
					shopInteractConfig.Parent = npcChar;
				end
				dialog:InteractRequest(shopInteractConfig);
			end);
			
		end
	end 
end

return Dialogues;