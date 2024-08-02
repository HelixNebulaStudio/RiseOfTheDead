local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

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
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
		local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.05);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
		end)
		
		dialog:AddChoice("shop_ratShop");
	end 
end

return Dialogues;