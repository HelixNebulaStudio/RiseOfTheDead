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
		Dialogue="Do you sell anything?";
		Reply="What do you want..?";
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
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		if modMission:IsComplete(player, 63) then
			dialog:AddChoice("shop_banditShop");
			
		end
	end 
end

return Dialogues;