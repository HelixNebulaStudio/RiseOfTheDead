local NpcDialogues = {};

NpcDialogues.Initial = {
	"*Ughhh*";
};

NpcDialogues.Dialogues = {
	---- Fail to meet requirements
	--{Tag="startFail1"; Dialogue=""; Reply="I don't think you can help me..."};
	
	---- Infected;
	--{MissionId=10; Tag="infected_letmehelp"; CheckMission=10; Dialogue="Please let me help you."; Reply="I can't be saved, I'm infected. Don't waste your resources on me."};
	--{MissionId=10; Tag="infected_insist"; Dialogue="It's okay, I want to help you."; Reply="*sigh* If you insist, please get me some antibiotics for this wound from Sunday's convenient store."};
	--{MissionId=10; Tag="infected_foundit"; Dialogue="Here's the antibiotics."; Reply="Thanks, it's best if you leave me here for now."};
	--{MissionId=10; Tag="infected_helper"; Dialogue="I can't find the antibiotics anywhere..."; Reply="Is there a doctor you could ask the antibiotics from?"};
	
};

return NpcDialogues;