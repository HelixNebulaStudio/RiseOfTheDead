
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"Ummmm, what should I do?";
	"Hey bro, should I honestly play this card or that card?";
};

NpcDialogues.Dialogues = {
	{Tag="shop_ratShop";
	Dialogue="What do you have for sale?";
	Reply="You'll honestly find everything you need here.";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end
	};
	
	{Tag="general_fold"; Dialogue="You should fold."; 
		Reply="How do I fold!?"};
	
	{Tag="general_commodities"; Dialogue="What do you do around here?"; 
		Reply="I honestly just salvage commodities.. While we're in that topic, I could trade you some blueprints for your commodities.."};
};

return NpcDialogues;