local NpcDialogues = {};

--[[
	Personality: Cheerful
	
]]

NpcDialogues.Initial = {
	"Hello!";
};

NpcDialogues.Dialogues = {
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Confident"; Reply="Hello there. I have a deal for you..\n\nYou let me open shop in your base for R.A.T. and we'll give you bonuses for doing business with us.";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Smirk"; Dialogue="Sure, I'll take that deal..";
		Reply="Great! Let me get my things.."};
	{MissionId=55; Tag="shelter_decline"; Face="Suspicious"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="Oh well.."};
	
	--== Lvl0
	{Tag="shelter_new"; Face="Confident"; Reply="Cool, nice place.";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Skeptical"; 
		Reply="First thing's first, I'll need some materials to set up shop..";};
	
	{Tag="shelter_lvl1_choice1"; Face="Suspicious"; Dialogue="What do you need for the shop?";
		Reply="Get me 200 metal scraps, that should do for now."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give metal scraps*.";
		Reply="Thanks, I'll get to work.."};
	{Tag="shelter_lvl1_b"; Face="Welp"; Dialogue="I'll go get some metal scraps.";
		Reply="Alright."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Yeesh"; 
		Reply="*building*";};
	{Tag="shelter_lvl2_choice1"; Face="Question"; Dialogue="How's it going?";
		Reply="Er.. So far so good.."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Welp"; 
		Reply="$PlayerName, looks like I need some more stuff.";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="What do you need?";
		Reply="Hmmm, I'll need 60 wooden parts."};
	{Tag="shelter_lvl3_choice1_a"; Face="Welp"; Dialogue="Here you go. *give wood*.";
		Reply="Great, thanks!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, soo why do you work for R.A.T.?";
		Reply="Oh, they had food. I just wanted food, but now I also got security, so that's great!"};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, it's done.. One last thing, where can I get some food around here. I'm starving from building..";};
	{Tag="shelter_lvl4_choice1"; Face="Smirk"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh, alright."};
	
	{Tag="shelter_lvl4_choice2"; Face="Serious"; Dialogue="What were you before the apocalypse?";
		Reply="Oh, I was a security guard."};
	
	--== Shop
	{Tag="shelter_shop"; Face="Smirk"; Dialogue="What do you have for sale?";
		Reply="We got all the time to trade.";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("ShopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.ShopInteractable, npcModel.PrimaryPart);
			end
		end
	};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="*sigh*, here's my status report."};
};

return NpcDialogues;