local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"You must be far from home..";
	"*Sigh* What's lost is lost..";
	"There's no hope.";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Sure.. Hold tight."};
	{Tag="shop_ratShop";
		Dialogue="What do you have for sale?";
		Reply="Have a look..";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end};
};

return NpcDialogues;