local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hmmmm..? What do you want?";
	"Need something or what?";
};

NpcDialogues.Dialogues = {
	-- Fail to meet requirements
	{Tag="startFail1"; Dialogue=""; Reply="Come back later, I'm not yet ready."};
	{Tag="startFail2"; Dialogue=""; Reply="I think you're not ready for this, come back when you're ready."};
	{Tag="startFail3"; Dialogue=""; Reply="Umm maybe you need to get better before you do this."};
};

return NpcDialogues;