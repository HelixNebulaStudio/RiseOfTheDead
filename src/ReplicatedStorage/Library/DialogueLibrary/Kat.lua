local NpcDialogues = {};

--[[
	Personality: Bubbly
	
]]

NpcDialogues.Initial = {
	"Heya!";
};

NpcDialogues.Dialogues = {
	--== Lvl0
	{Tag="shelter_new"; Face="Worried"; Reply="Wow, what a place..";};
	
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Angry"; 
		Reply="Ouch..";};
	
	{Tag="shelter_lvl1_choice1"; Face="Worried"; Dialogue="What do you need for your injuries?";
		Reply="Hmm, I think I'll need about 2 medkits.."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give 2 medkits*.";
		Reply="Ohh, that's just what I needed."};
	{Tag="shelter_lvl1_b"; Face="Worried"; Dialogue="Ok, wait here.";
		Reply="Alrighty."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Welp"; 
		Reply="This stings..";};
	{Tag="shelter_lvl2_choice1"; Face="Happy"; Dialogue="How are you feeling?";
		Reply="Much better, still need some time though.."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Disgusted"; 
		Reply="Hey, $PlayerName, I'm kinda hungry.";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Ohh, okay, thank you!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, what's your job before the apocalypse?";
		Reply="Lifeguard at the W.D. Lighthouse! I do miss my job.."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, is there anyway I could contribute?";};
	{Tag="shelter_lvl4_choice1"; Face="Excited"; Dialogue="Could you be our medic?";
		Reply="Absolutely!"};
	{Tag="shelter_lvl4_choice2"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="I feel like brand new!"};
	
	
	--== Medic
	{Tag="shelter_medic"; Face="Excited"; Dialogue="Can you heal me?";
		Reply="Of course!."};
	
	--== Dev Branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="Oh sure! Here you go."};
};

return NpcDialogues;