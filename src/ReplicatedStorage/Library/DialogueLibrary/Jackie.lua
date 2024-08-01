local NpcDialogues = {};

--[[
	Personality: Funny
	
]]

NpcDialogues.Initial = {
	"Hey hey";
};

NpcDialogues.Dialogues = {	
	--== Lvl0
	{Tag="shelter_new"; Face="Confident"; Reply="Is this place a palace or what.";};
	
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
		Reply="*building* ...";};
	{Tag="shelter_lvl2_choice1"; Face="Oops"; Dialogue="How's it going?";
		Reply="Er.. So far so good.."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Oops"; 
		Reply="$PlayerName, looks like I need some more stuff.";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="What do you need?";
		Reply="Hmmm, I'll need 60 wooden parts."};
	{Tag="shelter_lvl3_choice1_a"; Face="Welp"; Dialogue="Here you go. *give wood*.";
		Reply="Great, thanks!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, soo why do you work for R.A.T.?";
		Reply="I was a colleague of the leader of R.A.T. before everything gone down the drain. He recruited us as soon as the apocalypse started annnd I was like 'Apes together strong.' so I joined."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, it's done.. One last thing, where can I get some food around here. I'm starving from building..";};
	{Tag="shelter_lvl4_choice1"; Face="Smirk"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh, good. It's actual food right? Not the dried insects some have to resort to eating.."};
	
	{Tag="shelter_lvl4_choice2"; Face="Serious"; Dialogue="What were you before the apocalypse?";
		Reply="Err, I worked for a hedge fund company.."};
	
	--== Shop
	{Tag="shelter_shop"; Face="Smirk"; Dialogue="What do you have for sale?";
		Reply="I got everything here in my trench coat.. Just kidding, I'll have to contact R.A.T.";
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