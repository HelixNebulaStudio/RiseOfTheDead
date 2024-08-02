local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="No, I'm not the Cooper you're thinking of.";
	};
	["init2"]={
		Reply="I don't think he knows how to play this game..";
	};
	["init3"]={
		Reply="What do ya want, no funny stuff.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["shop_ratShop"]={
		Say="Can I buy something?";
		Reply="Sure, what do ya need?";
			ReplyFunction=function(dialogPacket)
				local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end
	};
	
	["general_win"]={
		Say="Looks like you're going to win."; 
		Reply="Yeah, but I have no clueee what's taking David so long for his move.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		dialog:AddChoice("shop_ratShop");
		dialog:AddChoice("general_win");
	end 
end

return Dialogues;