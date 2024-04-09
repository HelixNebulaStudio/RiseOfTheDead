local NpcDialogues = {};

--[[
	Personality: Blunt
	
]]

NpcDialogues.Initial = {
	"What's up?";
	"Look who we have here..";
};

NpcDialogues.Dialogues = {
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Confident"; Reply="Hey, I'm just a scrappy but I can turn your poop into gold.";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Smirk"; Dialogue="Is that soo? Come on in.";
		Reply="Thanks, I'll just need some stuff before we begin."};
	{MissionId=55; Tag="shelter_decline"; Face="Suspicious"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="One person's trash is another person's treasure, see ya then."};
	
	--== Lvl0
	{Tag="shelter_new"; Face="Confident"; Reply="Now.. Where's the toilet?";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Skeptical"; 
		Reply="Alright, first, I'll need some materials.";};
	
	{Tag="shelter_lvl1_choice1"; Face="Suspicious"; Dialogue="Okay, what do you need?";
		Reply="Get me 3 gears, that should do for now."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give gears*.";
		Reply="Nice.. I hope I'm not grinding your gears. Hahah"};
	{Tag="shelter_lvl1_b"; Face="Welp"; Dialogue="I'll go get some gears.";
		Reply="Chop chop."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Yeesh"; 
		Reply="*tinkering* ...";};
	{Tag="shelter_lvl2_choice1"; Face="Question"; Dialogue="How's it going?";
		Reply="Very scrappy.."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Welp"; 
		Reply="$PlayerName, I'm just missing a few stuff.";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="What do you need?";
		Reply="Hmmm, I'll need about 4 Steel Fragments."};
	{Tag="shelter_lvl3_choice1_a"; Face="Welp"; Dialogue="Here you go. *give steel*.";
		Reply="Ah, the finest steel!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, soo what do you do again?";
		Reply="If you give me enough junk, I can give you something useful. Just make sure the item is recyclable."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, thanks for letting me settle here. *stomach growls*";};
	{Tag="shelter_lvl4_choice1"; Face="Smirk"; Dialogue="I heard that, there's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh yeah, thanks!"};
	
	{Tag="shelter_lvl4_choice2"; Face="Serious"; Dialogue="How did you survive the apocalypse?";
		Reply="Just me being a handy man got me quite far."};
	
	--== Recycle
	{Tag="shelter_recycle"; Face="Smirk"; Dialogue="I want to recycle some stuff.";
		Reply="Let's see what you got.";
	};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="*sigh*, here's my status report."};
};

return NpcDialogues;