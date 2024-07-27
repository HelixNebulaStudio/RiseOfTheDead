local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hello, how may I help you?";
	"Hey, how are you?";
	"Yes? Do you need some help?";
};

NpcDialogues.Dialogues = {
	-- General
	{Tag="general_takenOver"; Dialogue="I still can't believe what happened to the world."; 
		Reply="Me neither, the world is taken over by the zombies."};
	{Tag="general_russellSaved"; Dialogue="How did you end up here?"; 
	Reply="I was trapped in my clothing store for 8 hours when everything happened, then Russell showed up. Killing a bunch of the dead to get me out of the store and brought me here."};
	{Tag="general_howsNick"; Dialogue="How are you?"; 
		Reply="Pretty well, I was terrified when I was trapped outside, now I feel much safer now."};
};

return NpcDialogues;