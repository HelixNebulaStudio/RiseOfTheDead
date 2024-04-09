local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hello, how may I help you?";
	"Hey, how are you?";
	"Yes? Do you need some help?";
};

NpcDialogues.Dialogues = {
	-- Pigeon Post
	{MissionId=14; Tag="pigeonPost_help"; CheckMission=14; Dialogue="What do you need help with?"; 
		Reply="I spoke to Robert before he left about his safehouse. He said they have 4 or 5 survivors, I don't quite remember.."};
	{MissionId=14; Tag="pigeonPost_hadfive"; Dialogue="They have 5 survivors."; 
		Reply="Oh, alright. Since you've been there, did you meet a person named Jane?"};
	{MissionId=14; Tag="pigeonPost_yes"; Dialogue="Yes, I did."; 
		Reply="OH THANK GOODNESS. I need you to help me let her know that I'm here, she must be worried sick.\n\nI can't really go out there, I do not know how to use a gun.."};
	{MissionId=14; Tag="pigeonPost_sure"; Dialogue="Sure, what do you want me to tell her?"; 
		Reply="Let her know that I'm alright and I'm in a safehouse. Tell her not to go out there to look for me.. It's too dangerous, when the time's right, I will come for her."};
	{MissionId=14; Tag="pigeonPost_gotit"; Dialogue="Alright, got it."; 
		Reply="Thanks a lot, good luck out there."};
	
	{MissionId=14; Tag="pigeonPost_wrong"; Dialogue="Ummm, I'm sorry but she isn't the Jane you know."; 
		Reply="What! What do you mean?"};
	{MissionId=14; Tag="pigeonPost_didntKnow"; Dialogue="She said she didn't know you."; 
		Reply="Noooooo, where could she be??"};
	{MissionId=14; Tag="pigeonPost_sayHi"; Dialogue="She told me to say hi though."; 
		Reply="*sob*"};
	
	-- General
	{Tag="general_takenOver"; Dialogue="I still can't believe what happened to the world."; 
		Reply="Me neither, the world is taken over by the zombies."};
	{Tag="general_russellSaved"; Dialogue="How did you end up here?"; 
	Reply="I was trapped in my clothing store for 8 hours when everything happened, then Russell showed up. Killing a bunch of the dead to get me out of the store and brought me here."};
	{Tag="general_howsNick"; Dialogue="How are you?"; 
		Reply="Pretty well, I was terrified when I was trapped outside, now I feel much safer now."};
};

return NpcDialogues;