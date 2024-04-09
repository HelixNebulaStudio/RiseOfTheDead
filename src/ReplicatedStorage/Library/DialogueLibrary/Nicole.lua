local NpcDialogues = {};

--[[
	Personality: Blunt
	
]]

NpcDialogues.Initial = {
	"Hey";
};

NpcDialogues.Dialogues = {
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Worried"; Reply="Ahhh, what was that chasing me!? God, my arm! Hey, I can't go back out there, I'm staying here.";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Worried"; Dialogue="Sure, stay as long as you want..";
		Reply="Thank god.. Err, I mean thank you.."};
	{MissionId=55; Tag="shelter_decline"; Face="Worried"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="Fine, I'll look for another place."};
	
	--== Lvl0
	{Tag="shelter_new"; Face="Worried"; Reply="Pretty cosy place.";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Skeptical"; 
		Reply="This pain ain't going away for a while..";};
	
	{Tag="shelter_lvl1_choice1"; Face="Worried"; Dialogue="What do you need for your injuries?";
		Reply="Hmmm, 2 medkits, *sigh*, this is going to take a while to heal."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give 2 medkits*.";
		Reply="Thanks, I'll patch up my arm and let it heal.."};
	{Tag="shelter_lvl1_b"; Face="Worried"; Dialogue="Ok, wait here.";
		Reply="Okay."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Welp"; 
		Reply="*healing* ...";};
	{Tag="shelter_lvl2_choice1"; Face="Skeptical"; Dialogue="How are you feeling?";
		Reply="Still hurts, I can't heal that quick."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Welp"; 
		Reply="$PlayerName, is there any food around here?";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Hmmm, one per person.. Okay, thanks."};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, what's your job before the apocalypse?";
		Reply="Oh, I was a doctor."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, got anything for me to do here?";};
	{Tag="shelter_lvl4_choice1"; Face="Smirk"; Dialogue="Could you be our medic?";
		Reply="Alright."};
	{Tag="shelter_lvl4_choice2"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="The pain is bearly noticable now."};
	
	
	--== Medic
	{Tag="shelter_medic"; Face="Welp"; Dialogue="Can you heal me?";
		Reply="Again?"};
	
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="*sigh*, here's my status report."};
};

return NpcDialogues;