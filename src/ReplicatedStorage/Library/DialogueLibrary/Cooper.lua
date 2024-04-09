
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"No, I'm not the Cooper you're thinking of.";
	"I don't think he knows how to play this game..";
	"What do ya want, no funny stuff.";
};

NpcDialogues.Dialogues = {
	{Tag="shop_ratShop";
	Dialogue="Can I buy something?";
	Reply="Sure, what do ya need?";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
		if npcModel:FindFirstChild("shopInteractable") then
			local localPlayer = game.Players.LocalPlayer;
			local modData = require(localPlayer:WaitForChild("DataModule"));

			modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
		end
	end
	};
	
	{Tag="general_win"; Dialogue="Looks like you're going to win."; 
		Reply="Yeah, but I have no clueee what's taking David so long for his move."};
};

return NpcDialogues;