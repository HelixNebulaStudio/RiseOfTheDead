local NpcDialogues = {};

NpcDialogues.Initial = {
	"Who do you think you are talking to?";
	"I am the danger.";
	"I would watch my steps if I was you!";
};

NpcDialogues.Dialogues = {
	-- Bandits Recruitment
	{MissionId=63; Tag="theRecruit_zarkInit"; Face="Confident"; 
		Reply="Well well well, look who it is..";};

	{MissionId=63; Tag="theRecruit_recruit1"; Face="Confident";
		Dialogue="I heard you were recruiting and you are looking for me..";
		Reply="Bold of you to come directly to me, hahah. You are quite a warrior, and it would be great to have someone like you among our ranks."};
	{MissionId=63; Tag="theRecruit_recruit2"; Face="Confident";
		Dialogue="I only came to talk, what makes you think I want to join you?";
		Reply="It's kill or to be killed, allow me to convince you to join us.."};

	{MissionId=63; Tag="theRecruit_zarkInit2"; Face="Confident"; 
		Reply="Anyways, I will need somethings from you.. Remember your friend Stan?";};
	{MissionId=63; Tag="theRecruit_recruit3"; Face="Skeptical";
		Dialogue="Yeah, you shot him dead and now he's in your rejuvenation chamber which you wanted to trade to the Rats..";
		Reply="Yes, I had a hunch he was an infector, but he wasn't the one which took out one of our squads."};
	{MissionId=63; Tag="theRecruit_recruit4"; Face="Confident";
		Dialogue="So what are you doing with Stan?";
		Reply="Stan has some levels of immunity to the parasite.. You are going to help me if you want to save him. "};
	{MissionId=63; Tag="theRecruit_recruit5"; Face="Confident";
		Dialogue="What do you need?";
		Reply="Get these items, and bring it back to the mall. Loran will be there to collect."};
	
};

return NpcDialogues;