local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="You must be far from home..";
	};
	["init2"]={
		Reply="*Sigh* What's lost is lost..";
	};
	["init3"]={
		Reply="There's no hope.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Say="Can you heal me please?";
		Reply="Sure.. Hold tight.";
	};
	["shop_ratShop"]={
		Say="What do you have for sale?";
		Reply="Have a look..";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

		dialog:AddChoice("heal_request", function(dialog)
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.05);
			shared.modEventService:ServerInvoke("Dialogue_BindMedicHeal", {}, player, dialog);
		end)
		
		dialog:AddChoice("shop_ratShop", function()
			local npcChar = dialog.Character;

			local shopInteractConfig = npcChar:FindFirstChild("ShopInteractable");
			if shopInteractConfig == nil then
				shopInteractConfig = modInteractables.createInteractable("Shop");
				shopInteractConfig.Name = "ShopInteractable";
				shopInteractConfig:SetAttribute("ShopType", "Rats");
				shopInteractConfig.Parent = npcChar;
			end
			dialog:InteractRequest(shopInteractConfig);

		end);
	end 
end

return Dialogues;