local NpcDialogues = {};

--[[
	Personality: Elder
	
]]

NpcDialogues.Initial = {
	"Speak.";
};

NpcDialogues.FortuneAnswers = {
	"It is certain.";
	"It is decidedly so.";
	"Without a doubt.";
	"Yes, definitely.";
	"You may rely on it.";
	"As I see it, yes.";
	"Most likely.";
	"Outlook good.";
};


NpcDialogues.Dialogues = {
	-- Another Survivor
	{MissionId=55; Tag="shelter_init"; Face="Skeptical"; Reply="Let me stay, and I will tell you your fortune..";};
	
	{MissionId=55; Tag="shelter_accept"; Face="Smirk"; Dialogue="Ummm, okay.";
		Reply="Very well.."};
	{MissionId=55; Tag="shelter_decline"; Face="Frustrated"; Dialogue="I'm afraid we can't accept anyone at the moment.";
		Reply="I see.. I hope this place will not be ill fated.."};
	
	--== Lvl0
	{Tag="shelter_new"; Face="Smirk"; Reply="Yes... yes.. I can work with this..";};
	
	--== Lvl1 
	{Tag="shelter_lvl1_init"; Face="Skeptical"; 
		Reply="As promised, I will tell you your fortune. However, I will need to channel my energy..";};
	
	{Tag="shelter_lvl1_choice1"; Face="Suspicious"; Dialogue="Do you need any help?";
		Reply="Hmmm, help would be good. Bring me a can of bloxy cola.."};
	{Tag="shelter_lvl1_a"; Face="Joyful"; Dialogue="Here you go. *give bloxy cola*.";
		Reply="Good, this will have to be boiled.."};
	{Tag="shelter_lvl1_b"; Face="Ugh"; Dialogue="Let me go get a can of bloxy cola.";
		Reply="Very well.."};
	
	
	--== Lvl2
	{Tag="shelter_lvl2_init"; Face="Yeesh"; 
		Reply="*boiling bloxy cola*";};
	{Tag="shelter_lvl2_choice1"; Face="Serious"; Dialogue="How's it going?";
		Reply="This is a delicate process.. Now.. shoo."};
	
	
	--== Lvl3
	{Tag="shelter_lvl3_init"; Face="Welp"; 
		Reply="Hmmm, something's missing..";};
	
	{Tag="shelter_lvl3_choice1"; Face="Surprise"; Dialogue="What do you need?";
		Reply="I think I'll need another ingredient.. A purple lemon.."};
	{Tag="shelter_lvl3_choice1_a"; Face="Welp"; Dialogue="Here you go. *give purple lemon*.";
		Reply="Good, good.."};
	{Tag="shelter_lvl3_choice1_b"; Face="Question"; Dialogue="Where do I find purple lemons?";
		Reply="Hmm, all over Wrighton Dale.. They fermented lemons in a special liquid.."};
	
	{Tag="shelter_lvl3_choice2"; Face="Serious"; Dialogue="Hey, soo are you a witch or something?";
		Reply="I am a fortune teller, I can foresee glimpse of the future and patterns in your past.."};
	
	
	--== Lvl4
	{Tag="shelter_lvl4_init"; Face="Skeptical"; 
		Reply="$PlayerName, I do not sense your past.. As if it has been erased from your memory.. Quite peculiar..";};
	{Tag="shelter_lvl4_choice1"; Face="Suspicious"; Dialogue="Yeah.. I woke up from a crash trying to get away from here. Lost my memories of anything before that..";
		Reply="Hmmmm, fasinating.."};
	
	{Tag="shelter_lvl4_choice2"; Face="Serious"; Dialogue="How did you become a fortune teller?";
		Reply="Ever since the apocalypse began, my foresight guided me.. Though it may be vague, I believe it holds true in the end."};
	
	--== Shop
	{Tag="shelter_fortunetell"; Face="Confident"; AskMe=true;
		Reply="Ask me anything and I will tell you your fortune..";};
	
	--==Dev branch
	{Tag="shelter_report"; Dialogue="[Dev Branch] Status report";
		Reply="*sigh*, here's my status report."};
};

return NpcDialogues;