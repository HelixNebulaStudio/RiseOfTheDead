local NpcDialogues = {};

--[[
	Personality: Grumpy
	
]]

NpcDialogues.Initial = {
	"Well?";
};

NpcDialogues.Dialogues = {
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Worried"; Reply="God, that stupid thing almost tore my arm off! I can't believe this but I really need to stay here for a bit.";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Worried"; Dialogue="Sure, stay as long as you want..";
		Reply="That's what I like to hear."};
	{MissionId=55; Tag="shelter_decline"; Face="Worried"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="What! What do you mean."};
	
	--== Lvl0
	{Tag="shelter_new"; Face="Skeptical"; Reply="Hmm, this place needs improvement.";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Frustrated"; 
		Reply="Ugh, this bloody hurts.";};
	
	{Tag="shelter_lvl1_choice1"; Face="Worried"; Dialogue="What do you need for your injuries?";
		Reply="2 medkits, make it quick."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give 2 medkits*.";
		Reply="There we go.. Much better."};
	{Tag="shelter_lvl1_b"; Face="Worried"; Dialogue="Ok, wait here.";
		Reply="Hurry."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Welp"; 
		Reply="Hmmm, I don't like to be watched while I'm doing this..";};
	{Tag="shelter_lvl2_choice1"; Face="Happy"; Dialogue="How are you feeling?";
		Reply="Never better.. Still need to rest though."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Smirk"; 
		Reply="I'm hungry, $PlayerName, where's the food?";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Good! People better follow the rules."};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, what's your job before the apocalypse?";
		Reply="I lived in the cabins near a camp site on mount Lottarocks, people come to be for help if they get injuired during their camp."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Confident"; 
		Reply="$PlayerName, I need something to do.";};
	{Tag="shelter_lvl4_choice1"; Face="Serious"; Dialogue="Could you be our medic?";
		Reply="Alright."};
	{Tag="shelter_lvl4_choice2"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="Like I resurrected."};
	
	
	--== Medic
	{Tag="shelter_medic"; Face="Skeptical"; Dialogue="Can you heal me?";
		Reply="Here *heals*, do you need me to watch your back out there?"};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="Hmmm, here."};
};

return NpcDialogues;