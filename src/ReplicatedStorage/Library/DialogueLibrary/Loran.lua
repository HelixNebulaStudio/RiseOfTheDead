local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"Ugn, it's you..";
	"Not interested, shoo.";
};

NpcDialogues.Dialogues = {
	{Tag="shop_banditShop";
		Dialogue="Do you sell anything?";
		Reply="What do you want..?";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end};
};

return NpcDialogues;