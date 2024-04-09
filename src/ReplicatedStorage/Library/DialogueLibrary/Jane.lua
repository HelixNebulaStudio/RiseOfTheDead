local NpcDialogues = {};

NpcDialogues.Initial = {
	"I want to see my friends again..";
	"We can't survive like this for long..";
	"Where are the national guards?!";
};

NpcDialogues.Dialogues = {
	{Tag="thanks_noproblem"; Dialogue="You're welcome, I'm just trying to save as much people as possible."; Reply="Is it true that there's another safehouse with other survivors?"};
	{Tag="thanks_othersafehouse"; Dialogue="Yes, there are other survivors in the warehouse opposite of the Bloxmart entrance."; Reply="Oh, it's great to hear that we aren't the only survivors."};
	{Tag="thanks_dontmindstaying"; Dialogue="Is it okay if I stay here for a while?"; Reply="Sure, make yourself at home."};
	
	-- Pigeon Post
	{MissionId=14; Tag="pigeonPost_what"; Dialogue="Umm hey.."; Reply="Hey."};
	{MissionId=14; Tag="pigeonPost_whosNick"; Dialogue="Nick wanted me to tell you that he's safe and that you do not have to worry about going out to look for him because it is dangerous outside."; Reply="Oh err.. umm... Who's Nick?"};
	{MissionId=14; Tag="pigeonPost_oh"; Dialogue="Oh.. Umm... I guess he thought you were the Jane he knows. It'll be hard for me to break it to him.."; Reply="Oh dear, anyways, tell him I said hi."};

	-- Spring Killing;
	{MissionId=21; Tag="springkill_yes"; CheckMission=21; Dialogue="Yes, I'm up for it."; Reply="Bloxmart, the bank and the factory. You know the places.."};
	{MissionId=21; Tag="springkill_done"; Dialogue="I've killed them all."; Reply="Hurray! I feel much safer already.."};
	{MissionId=21; Tag="springkill_notYet"; Dialogue="Still On it.."; Reply="Good luck~"};

};

return NpcDialogues;