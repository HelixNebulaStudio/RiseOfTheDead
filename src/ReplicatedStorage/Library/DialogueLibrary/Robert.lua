local NpcDialogues = {};

NpcDialogues.Initial = {
	"Thanks again, dude.";
	"I feel so much better now.";
};

NpcDialogues.Dialogues = {
	-- The Investigation
	{MissionId=52; Tag="investigation_sus"; Face="Smile";
		Dialogue="Oh umm, what are doing here?";
		Reply="Just checking this place out, not sure why it's blocked up.. It might have some useful supplies."};
	{MissionId=52; Tag="investigation_lure"; Face="Skeptical";
		Dialogue="Robert, Nate needs our help. Come, I think he's in the basement.";
		Reply="Oh alright.."};
	
	
	-- General
	{Tag="general_salads"; Face="Hehe"; Dialogue="How do you make your salads?"; Reply="2 purple lemons and boiled bloxy cola."};
	{Tag="general_funny"; Face="Oops"; Dialogue="You're funny."; Reply="No you."};
};

return NpcDialogues;