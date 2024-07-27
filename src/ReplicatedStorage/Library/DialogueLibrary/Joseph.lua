local NpcDialogues = {};

NpcDialogues.Initial = {
	"These crops can keep us going for years.";
	"Jesus.. I almost forgot to water the crops..";
	"One step closer to becoming self sustainable..";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Cmon' closer and I'll patch you up."};

	{Tag="lostArm_muchBetter"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="Much better now.. Definitely going to miss my left arm.. Going to need a hand later though, hahah.."};
};



return NpcDialogues;