local NpcDialogues = {};

NpcDialogues.Initial = {
	"Why buy tomorrow when you can buy today!";
};

NpcDialogues.Dialogues = {
	{Tag="aGoodDeal_questions"; Dialogue="Hey, this is the first time you are outside the shop!"; 
		Reply="Yes, I wanted to take a breath of the fresh air.."};
	{Tag="aGoodDeal_org"; Dialogue="Who do you work for?"; 
		Reply="R.A.T., now stop asking.."};
	{Tag="aGoodDeal_why"; Dialogue="Why are you working in this apocalypse?"; 
		Reply="I work for them and they protect me alright? I'm not going to answer anymore questions."};

};

return NpcDialogues;