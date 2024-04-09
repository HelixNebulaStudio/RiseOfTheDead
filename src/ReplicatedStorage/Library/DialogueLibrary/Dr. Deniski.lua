local NpcDialogues = {};

NpcDialogues.Initial = {
	"If you don't feel so well, come to me.";
	"Hey, I'm a doctor, I can help you out if you need.";
	"Want to heal up? I can help you with that.";
};

NpcDialogues.Dialogues = {
	-- Intro
	{Tag="heal_request"; Dialogue="Can you heal me please?"; 
		Reply="No problem! You will be healed up in no time, see you around!"};
	
	-- General
	{Tag="general_cost"; Dialogue="How much should I pay for healing?"; 
		Reply="It's absolutely free! I only ask for some favors every now and then."};
	{Tag="general_background"; Dialogue="How did you become a doctor?"; 
		Reply="I studied medical science, and I find it very interesting.\n\nI then started making my own medicine for different treatments, however this virus outbreak is not something I can fix."};
	{Tag="general_teachMe"; Dialogue="Can you teach me medical science?"; 
		Reply="Ehhh, no."};
	
	-- Jefferson
	{MissionId=10; Tag="jefferson_antibiotics"; Dialogue="Do you have any extra antibiotics? Someone is wounded and he really needs it.";
		Reply="Hmmm.. Alright."};
};

return NpcDialogues;