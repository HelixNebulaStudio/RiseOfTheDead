local NpcDialogues = {};

NpcDialogues.Initial = {
	"Why buy tomorrow when you can buy today!";
};

NpcDialogues.Dialogues = {
	-- A Good Deal;
	{Tag="aGoodDeal_questions"; Dialogue="Hey, this is the first time you are outside the shop!"; 
		Reply="Yes, I wanted to take a breath of the fresh air.."};
	{Tag="aGoodDeal_org"; Dialogue="Who do you work for?"; 
		Reply="R.A.T., now stop asking.."};
	{Tag="aGoodDeal_why"; Dialogue="Why are you working in this apocalypse?"; 
		Reply="I work for them and they protect me alright? I'm not going to answer anymore questions."};
	{MissionId=16; Tag="aGoodDeal_start"; CheckMission=16; Dialogue="Sure, I can help."; 
		Reply="Alright, find me 2 Igniters but don't take too long. I got customers waiting.."};
	
	{MissionId=16; Tag="aGoodDeal_notYet"; Dialogue="Still working on it."; Reply="Alright, but don't take too long. I got customers waiting.."};
	{MissionId=16; Tag="aGoodDeal_done"; Dialogue="Here you go."; 
		Reply="Alright, great, come back tomorrow. I might have some interesting items to offer for more of your work."};

};

return NpcDialogues;