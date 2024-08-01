local NpcDialogues = {};

--[[
	Personality: Blunt
	
]]

NpcDialogues.Initial = {
	".. Hey";
	"*cough* *cough*";
};

NpcDialogues.Dialogues = {
	--== Lvl0
	{Tag="shelter_new"; Face="Confident"; Reply="This place will do..";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Skeptical"; 
		Reply="Alright, let's cut to the chase. I'm going to need some items to start recycling..";};
	
	{Tag="shelter_lvl1_choice1"; Face="Suspicious"; Dialogue="What are you looking for?";
		Reply="Let's go with 2 gears first."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give 2 gears*.";
		Reply="Thanks, I'll get to work.."};
	{Tag="shelter_lvl1_b"; Face="Welp"; Dialogue="I'll go get some gears.";
		Reply="Very well."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Yeesh"; 
		Reply="*tinkering* ...";};
	{Tag="shelter_lvl2_choice1"; Face="Question"; Dialogue="How's it going?";
		Reply="Almost done.."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Welp"; 
		Reply="*cleans hand with cloth* Okay, going to need another thing..";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="What's that?";
		Reply="4 steel fragments, pronto."};
	{Tag="shelter_lvl3_choice1_a"; Face="Welp"; Dialogue="Here you go. *give steel fragments*.";
		Reply="Great, thanks!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Soo, what is recycling?";
		Reply="Oh, just give me some of you unwanted items, if they are recyclable, I could exchange something for them.."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, all right. It's all done, now where can I get some food?";};
	{Tag="shelter_lvl4_choice1"; Face="Smirk"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh, alright."};
	
	{Tag="shelter_lvl4_choice2"; Face="Serious"; Dialogue="Can I ask how does recycling actually work?";
		Reply="Well, if I told you, I would be out of a job, wouldn't I."};
	
	--== Recycle
	{Tag="shelter_recycle"; Face="Smirk"; Dialogue="I want to recycle some stuff.";
		Reply="Let's see what you got.";
	};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="*sigh*, here's my status report."};
};

return NpcDialogues;