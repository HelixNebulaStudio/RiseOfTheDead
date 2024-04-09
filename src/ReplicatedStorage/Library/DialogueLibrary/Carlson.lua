local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hello, how may I help you?";
	"Hey, how are you?";
	"Yes? Do you need some help?";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Sure, hold still..."};

	--== The Backup Plan
	{MissionId=22; Tag="thebackup_help"; CheckMission=22; Dialogue="Yup, what do you need help with?"; Reply="We are in deep trouble, we won't have enough food for the bandits the next time they attack.. I need you to help me get my hidden metal supplies to fortify this safehouse."};
	{MissionId=22; Tag="thebackup_thekey"; Dialogue="Absolutely, where is it?"; Reply="It's in the maintenance room, but I hid the room's key somewhere in the break room. Go find the key in order to unlock the maintenance room."};
	
	{MissionId=22; Tag="thebackup_gotit"; Dialogue="*Gives 1000 metal*"; Reply="Ah, there we go, it's all here.\n\nThanks a lot $PlayerName, we'll see how we can fortify the safehouse with it."};
	{MissionId=22; Tag="thebackup_wait"; Dialogue="Wait, I'm still getting it.."; Reply="Okay."};
	{MissionId=22; Tag="thebackup_stolen"; Dialogue="There wasn't any metal there."; Reply="Noooo! The bandits must have some how gotten it too. This is bad, what are we going to do?!\n\nThanks again for trying to help, we'll have to figure out something else."};

	--== Safety Safehouse
	{MissionId=28; Tag="safetysafehouse_goodGotTime"; CheckMission=28; Dialogue="Yeah, I got time."; Reply="Good, I think we should fortify the front with some metal walls."};
	{MissionId=28; Tag="safetysafehouse_badGotTime"; CheckMission=28; Dialogue="Yeah, I got time."; Reply="Good, since the bandits took our metal, we'll need metal to build some metal walls in the front."};
	
	-- ss bad dialog
	{MissionId=28; Tag="safetysafehouse_badMetal"; Dialogue="How much metal will we need?"; Reply="About 500 metal scrap should be enough, if the bandits had not taken my 1000 metal scraps, we wouldn't have to find metal ourselves."};
	{MissionId=28; Tag="safetysafehouse_truth"; Dialogue="Carlson, I'm so sorry. I actually kept the metal for myself that I took from your crate."; Reply="Oh... How could you.. Are you still going to help us?"};
	{MissionId=28; Tag="safetysafehouse_yes"; Dialogue="Yes, I will do anything to redeem from what I did."; Reply="Okay.. you'll have to get the metal to build the walls."};
	
	-- ss good dialog
	{MissionId=28; Tag="safetysafehouse_goodMetal"; Dialogue="How much metal will we need?"; Reply="About 500 metal scrap should be enough, we'll use my metal scraps. If there's spare, I can give it to you for my gratitude for helping us with this."};
	{MissionId=28; Tag="safetysafehouse_start"; Dialogue="Okay, I'll get started."; Reply="Alright."};
	{MissionId=28; Tag="safetysafehouse_complete"; Dialogue="I've added walls to the front of the safehouse, is that enough?"; Reply="Yes, that'll do for now. Thanks for your help."};
	{MissionId=28; Tag="safetysafehouse_askForMetal"; Dialogue="Hey, do you have any spare metal scraps?"; Reply="Yeah, I do, here have some."};

};

return NpcDialogues;