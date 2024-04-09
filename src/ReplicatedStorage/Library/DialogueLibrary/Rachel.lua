local NpcDialogues = {};

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--[[
	Personality: Formal
	
]]

NpcDialogues.Initial = modBranchConfigs.IsWorld("Safehome") and {"Hello!";} or {
	"Got any medical issues?";
	"Try not to injure yourself out there..";
	"If injured, consult me immediately to prevent an infection!";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Absolutely!.. Feeling much better now?"};
	
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Worried"; Reply="Hey $PlayerName.. Mind if I move into your safehouse? I don't want to stay in the train station anymore..";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Worried"; Dialogue="Sure, stay as long as you want..";
		Reply="Thanks! I injuired myself on my way here, I'll need to rest for a bit."};
	{MissionId=55; Tag="shelter_decline"; Face="Worried"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="Oh god, where will I go..."};
	
	
	--== Lvl0
	{Tag="shelter_new"; Face="Worried"; Reply="This place is not bad.";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Worried"; 
		Reply="This pain is almost unbearable..";};
	
	{Tag="shelter_lvl1_choice1"; Face="Worried"; Dialogue="What do you need for your injuries?";
		Reply="I will just need 2 medkits. That should be enough."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give 2 medkits*.";
		Reply="Thank you, that should help it."};
	{Tag="shelter_lvl1_b"; Face="Worried"; Dialogue="Ok, wait here.";
		Reply="Alright."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Welp"; 
		Reply="Alright, same procedure.. *healing*";};
	{Tag="shelter_lvl2_choice1"; Face="Happy"; Dialogue="How are you feeling?";
		Reply="Better, I think I will be better in a couple days."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Smile"; 
		Reply="$PlayerName, how does the food supply work here?";};
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="There's a freezer where we keep our food. One person can take one per day.";
		Reply="I see, well planned!"};
	{Tag="shelter_lvl3_choice2"; Face="Happy"; Dialogue="Hey, what's your job before the apocalypse?";
		Reply="Silly, you know I'm a nurse.."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Happy"; 
		Reply="$PlayerName, do you need any roles to be filled?";};
	{Tag="shelter_lvl4_choice1"; Face="Excited"; Dialogue="Could you be our medic?";
		Reply="Definitely."};
	{Tag="shelter_lvl4_choice2"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="Definitely better."};
	
	
	--== Medic
	{Tag="shelter_medic"; Face="Happy"; Dialogue="Can you heal me?";
		Reply="Here you go.."};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="Here's my status report, $PlayerName."};
};

return NpcDialogues;