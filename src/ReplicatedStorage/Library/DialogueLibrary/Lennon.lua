local NpcDialogues = {};

NpcDialogues.Initial = {
	"People say nothing is impossible, but I do nothing every day.";
	"To be sure of hitting the target, shoot first, and call whatever you hit the target.";
	"If you’re going to tell people the truth, be funny or they’ll kill you.";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Face="Joyful"; Dialogue="I'm hurt, can you help me?"; Reply="Why, of course!"};
	
	--== Sniper's nest;
	{MissionId=23; Tag="snipernest_help"; CheckMission=23; Dialogue="Ummm ok?"; Reply="Good good, are you good at killing zombies?"};
	{MissionId=23; Tag="snipernest_many"; Dialogue="YES! I'm the greatest zombie killer here."; Reply="WOW! There's are few zombies I want you to kill."};
	{MissionId=23; Tag="snipernest_yes"; Dialogue="Maybe.. What do you think?"; Reply="Errrr, you seem like you are really good at it. I believe you can do it, there's a few zombies I want you to kill."};
	{MissionId=23; Tag="snipernest_no"; Dialogue="Nah, it's hard to kill them."; Reply="Ohh darn, come back when you are better please."};
	
	{MissionId=23; Tag="snipernest_done"; Dialogue="Yeah, I helped you kill some zombies."; Reply="Oh! Umm, thank you?"};
	{MissionId=23; Tag="fail_invFull"; Dialogue="Yeah, I helped you kill some zombies."; Reply="Your inventory is quite full, comeback when you have some space available."};
};

return NpcDialogues;