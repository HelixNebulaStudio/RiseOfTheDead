local NpcDialogues = {};

NpcDialogues.Initial = {
	"Errr, hello again.";
	"Umm, I feel so much safer when you're here..";
	"The view of the sea is always so beautiful..";
};

NpcDialogues.Dialogues = {
	{Tag="general_hello"; Dialogue="Hello..."; Reply="...world!"};
	
	-- eightlegs
	{MissionId=20; Tag="eightlegs_sure"; Dialogue="What do you need help with?"; Reply="The Zpider is making a lot of noise and I have a hard time sleeping because of it..\nCould you kill it for me please?"};
	{MissionId=20; Tag="eightlegs_yeah"; CheckMission=20; Dialogue="Absoutely!"; Reply="Thanks.."};
	{MissionId=20; Tag="eightlegs_almost"; Dialogue="Still trying to get rid of it, sit tight."; Reply="Oh.. okay."};
	{MissionId=20; Tag="eightlegs_return"; Dialogue="I killed it. You don't have to worry about it now."; Reply="Thanks a lot.."};
	
	-- Calming Tunes
	{MissionId=36; Tag="calmingtunes_start"; Dialogue="Hey.. hey, it can't hurt you. Don't worry."; 
		Reply="It's driving me insane, I need something to calm me down."};
	{MissionId=36; Tag="calmingtunes_musicbox"; CheckMission=36; Dialogue="Okay, I have an idea. Wait here."; 
		Reply="Okay.."};
	
	{MissionId=36; Tag="calmingtunes_wait"; Dialogue="A music box might help calm you down."; 
		Reply="Hmm.. I'll be waiting, hope it works."};
	
	{MissionId=36; Tag="calmingtunes_give"; Dialogue="Here you go, a music box."; 
		Reply="Ooh, thanks dude."};
	{MissionId=36; Tag="calmingtunes_giveBoombox"; Dialogue="Here you go, a boom box."; 
		Reply="Erik needs a Music box instead of a Boombox."};
};

return NpcDialogues;