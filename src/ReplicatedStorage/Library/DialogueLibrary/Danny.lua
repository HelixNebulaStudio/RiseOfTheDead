local NpcDialogues = {};

NpcDialogues.Initial = {
	"A can of beans a day, keeps the doctor away..";
	"Needda patch up?";
	"I was a veterinarian, I guess it's not too different from an actual doctor right..?";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Patching you right up!"};
	
};

return NpcDialogues;