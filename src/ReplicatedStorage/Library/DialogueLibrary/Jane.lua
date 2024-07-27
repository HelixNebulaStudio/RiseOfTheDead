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

};

return NpcDialogues;