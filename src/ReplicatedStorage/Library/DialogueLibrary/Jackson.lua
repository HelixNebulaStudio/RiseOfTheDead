local NpcDialogues = {};

--[[
	Personality: Calm
	
]]

NpcDialogues.Initial = {
	"Sup!";
};

NpcDialogues.Dialogues = {
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Worried"; Reply="My goodness, I just got away from that thing and might have injured myself doing so. Hey, can I stay here for a bit?";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Worried"; Dialogue="Sure, stay as long as you want..";
		Reply="Why thank you."};
	{MissionId=55; Tag="shelter_decline"; Face="Worried"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="Ah well."};
	
	--== Lvl0
	{Tag="shelter_new"; Face="Worried"; Reply="Cool place!";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Skeptical"; 
		Reply="Oof, this hurts.";};
	
	{Tag="shelter_lvl1_choice1"; Face="Worried"; Dialogue="What do you need for your injuries?";
		Reply="I'll probably need 2 medkits."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give 2 medkits*.";
		Reply="Thanks, that should do it."};
	{Tag="shelter_lvl1_b"; Face="Worried"; Dialogue="Ok, wait here.";
		Reply="Sure."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Welp"; 
		Reply="A bandage here.. A bandage there..";};
	{Tag="shelter_lvl2_choice1"; Face="Happy"; Dialogue="How are you feeling?";
		Reply="The pain is much more bearable, thanks for asking."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Smile"; 
		Reply="Sooo, $PlayerName, where can I get food around here?";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh okay, thanks!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, what's your job before the apocalypse?";
		Reply="Oh, I was a veterinarian."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, is there anything I could do here?";};
	{Tag="shelter_lvl4_choice1"; Face="Oops"; Dialogue="Could you be our medic?";
		Reply="Sure!"};
	{Tag="shelter_lvl4_choice2"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="Much better, thanks for asking."};
	
	
	--== Medic
	{Tag="shelter_medic"; Face="Confident"; Dialogue="Can you heal me?";
		Reply="Patching you right up."};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="No probs, here's my status report."};
};

return NpcDialogues;