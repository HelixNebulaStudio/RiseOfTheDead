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
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end};

	-- Bandits Recruitment
	{MissionId=63; Tag="theRecruit_init"; Face="Frustrated"; 
		Reply="I'm going to start counting again..";};
	
	{MissionId=63; Tag="theRecruit_wait"; Face="Frustrated";
		Dialogue="Wait wait wait wait";
		Reply="...\n\n<b>Stranger:</b> Stop!"};

	{MissionId=63; Tag="theRecruit_help"; Face="Skeptical";
		Dialogue="Umm, sorry. I forgot what I'm suppose to look for.";
		Reply="You're dumber than you look. Zark said 2 Nekron Particulate Caches!"};
	{MissionId=63; Tag="theRecruit_nekronParticulateCache"; Face="Skeptical";
		Dialogue="Here's the 2 Nekron Particulate Caches.";
		Reply="Good...\n\nWhy are you still here?"};
};

return NpcDialogues;