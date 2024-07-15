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

};

return NpcDialogues;