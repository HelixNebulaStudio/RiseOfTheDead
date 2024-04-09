local NpcDialogues = {};

NpcDialogues.Initial = {
	"What's up?";
	"Good to see you safe.";
	"You look well.";
};

NpcDialogues.Dialogues = {
	-- The Investigation
	{MissionId=52; Tag="investigation_wakeUp"; Dialogue="Hey Dallas, wake up!!"; 
		Reply="Ohh.. God dumm... I was knocked out cold.."};
};

return NpcDialogues;