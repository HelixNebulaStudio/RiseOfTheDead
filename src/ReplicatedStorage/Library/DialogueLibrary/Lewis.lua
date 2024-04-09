
--==


local NpcDialogues = {};

NpcDialogues.Initial = {
	"Should have burned this place down when I had the chance.";
	"Easy come, easy go, as they say..";
	"Jesus H. Christ, I'm getting old.."
};

NpcDialogues.Dialogues = {
	{Tag="shop_ratShop";
	Dialogue="Do you sell anything?";
	Reply="Yes, that's what I do here.";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
		if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
		end
		end};
	
	{Tag="general_steel"; Dialogue="Umm, do you know where I can get steel fragments?"; 
		Reply="Oh, you came to the right place, I can exchange steel fragments for blueprints."};
};

return NpcDialogues;